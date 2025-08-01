//Sends resource files to client cache
/client/proc/getFiles(...)
	for(var/file in args)
		src << browse_rsc(file)

/proc/wrap_file(filepath)
	if(IsAdminAdvancedProcCall())
		// Admins shouldnt fuck with this
		to_chat(usr, "<span class='boldannounceooc'>File load blocked: Advanced ProcCall detected.</span>")
		message_admins("[key_name(usr)] attempted to load files via advanced proc-call")
		log_admin("[key_name(usr)] attempted to load files via advanced proc-call")
		return

	return file(filepath)

/proc/wrap_file2text(filepath)
	if(IsAdminAdvancedProcCall())
		// Admins shouldnt fuck with this
		to_chat(usr, "<span class='boldannounceooc'>File load blocked: Advanced ProcCall detected.</span>")
		message_admins("[key_name(usr)] attempted to load files via advanced proc-call")
		log_admin("[key_name(usr)] attempted to load files via advanced proc-call")
		return

	return file2text(filepath)


/client/proc/browse_files(root="data/logs/", max_iterations=10, list/valid_extensions=list("txt","log","htm", "html"))
	var/path = root

	for(var/i=0, i<max_iterations, i++)
		var/list/choices = flist(path)
		if(path != root)
			choices.Insert(1,"/")

		var/choice = input(src,"Choose a file to access:","Download",null) as null|anything in sortList(choices)
		switch(choice)
			if(null)
				return
			if("/")
				path = root
				continue
		path += choice

		if(copytext(path,-1,0) != "/")		//didn't choose a directory, no need to iterate again
			break
	var/extensions
	for(var/i in valid_extensions)
		if(extensions)
			extensions += "|"
		extensions += "[i]"
	var/regex/valid_ext = new("\\.([extensions])$", "i")
	if( !fexists(path) || !(valid_ext.Find(path)) )
		to_chat(src, "<font color='red'>Error: browse_files(): File not found/Invalid file([path]).</font>")
		return

	return path

#define FTPDELAY 200	//200 tick delay to discourage spam
#define ADMIN_FTPDELAY_MODIFIER 0.5		//Admins get to spam files faster since we ~trust~ them!
/*	This proc is a failsafe to prevent spamming of file requests.
	It is just a timer that only permits a download every [FTPDELAY] ticks.
	This can be changed by modifying FTPDELAY's value above.

	PLEASE USE RESPONSIBLY, Some log files can reach sizes of 4MB!	*/
/client/proc/file_spam_check()
	var/time_to_wait = GLOB.fileaccess_timer - world.time
	if(time_to_wait > 0)
		to_chat(src, "<font color='red'>Error: file_spam_check(): Spam. Please wait [DisplayTimeText(time_to_wait)].</font>")
		return 1
	var/delay = FTPDELAY
	if(holder)
		delay *= ADMIN_FTPDELAY_MODIFIER
	GLOB.fileaccess_timer = world.time + delay
	return 0
#undef FTPDELAY
#undef ADMIN_FTPDELAY_MODIFIER

/proc/pathwalk(path)
	var/list/jobs = list(path)
	var/list/filenames = list()

	while(jobs.len)
		var/current_dir = pop(jobs)
		var/list/new_filenames = flist(current_dir)
		for(var/new_filename in new_filenames)
			// if filename ends in / it is a directory, append to currdir
			if(findtext(new_filename, "/", -1))
				jobs += current_dir + new_filename
			else
				filenames += current_dir + new_filename
	return filenames

/proc/pathflatten(path)
	return replacetext(path, "/", "_")

/// Save file as an external file then md5 it.
/// Used because md5ing files stored in the rsc sometimes gives incorrect md5 results.
/// https://www.byond.com/forum/post/2611357
/proc/md5asfile(file)
	var/static/notch = 0
	// its importaint this code can handle md5filepath sleeping instead of hard blocking, if it's converted to use rust_g.
	var/filename = "tmp/md5asfile.[world.realtime].[world.timeofday].[world.time].[world.tick_usage].[notch]"
	notch = WRAP(notch+1, 0, 2**15)
	fcopy(file, filename)
	. = rustg_hash_file(RUSTG_HASH_MD5, filename)
	fdel(filename)
