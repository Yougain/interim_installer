#!/usr/bin/env ruby

require 'Yk/file_aux2'
require 'Yk/rlprompt'
require 'time'
require 'curses'
require 'Yk/proclist'
require 'Yk/misc_tz'


def getWH
	Curses.init_screen
	w = Curses.cols
	h = Curses.lines
	Curses.close_screen
	return [w, h]
end


class HashSet < Hash
	def insert (k, item)
		(self[k] ||= []).push item
	end
end


def lineNum (w, ln)
	ret = 0
	ln.each_line do |e|
		ret += ((e.size - 1) / w) + 1
	end
	return ret
end


def fmt (w, ln, cont)
	if cont.size >= w - 10
		cont = cont[0 ... w - 10]
	end
	ln = ln.chomp
	ln.gsub! /\t/, " "
	if w == nil || w == 0
		return ln + "\n"
	end
	if ln.size < w
		ln += "\n"
	elsif ln.size == w
		ln
	else
		ln[0...w] + fmt(w, cont + ln[w ... ln.size].strip, cont)
	end
end


if STDOUT.tty?
	cols, rows = getWH
else
	cols, rows = nil, nil
end


prform = Proc.new do |ln|
	ln.chomp!
	ln = ln[0...cols]
	print ln
	if ln.size != cols
		print "\n"
	else
		STDOUT.flush
	end
end

require 'Yk/generator__'

	args = []
	regexp = false
	mdat = nil
	progs = []
	pgs = []
	parentStep = nil
	allChild = false
	sendSig = nil
	force = nil
	ARGV.each__ do |g|
		case g.current
		when "-e"
			g.inc
			mdat = Regexp.new(g.current)
		when "-m"
			g.inc
			mdat = g.current
		when "-w"
			g.inc
			mdat = Regexp.new(/\b#{Regexp.escape(g.current)}\b/)
		when "-a"
			allChild = true
			next
		when "-T"
			sendSig = :TERM
			next
		when "-K"
			sendSig = :KILL
			next
		when "-H"
			sendSig = :HUP
			next
		when "-I"
			sendSig = :INT
			next
		when "-f"
			force = true
			next
		when "-s"
			g.inc
			sg = g.current
			if sg =~ /^SIG/
				sg = $'
			end
			sendSig = sg.intern;
		when "-?", "--help"
			print -%{
				usage: lsp COMMAND|PID [-m MATCH] [-e REGEXP] [-a] [-T] [-K] [-H] [-I] [-f] [-NUMBER]
				          -m MATCH  : Match command line by string.
            	          -e REGEXP : Match command line by regular expression.
				          -a        : Include all descendant processes.
				          -T        : Send TERM signal.
				          -H        : Send HUP signal.
				          -I        : Send INT signal.
                          -s SIGNAL : Send SIGNAL.
            	          -f        : Do not ask before send signals.
				          -NUMBER   : ancestral process above NUMBER generations.
			}
			exit 1
		when /^\-(\d+)$/
			parentStep = $1.to_i
		else
			progs.push g.current
		end
	end
	progs.each do |e|
		if e =~ /^\d+$/ && (tmp = ProcList.pid(e.to_i))
			pgs.push tmp
		elsif e =~ /^\/(.*)\/$/
			pgs.push *ProcList.prog(Regexp.new($1), mdat)
		else
			pgs.push *ProcList.prog(e, mdat)
		end
	end
	if progs.size == 0
		pgs.push *ProcList.prog(nil, mdat)
	end
	orgPgs = pgs
	pgs = ProcList.independent(pgs)
	if parentStep != nil
		pgsp = Hash.new
		pgs.each do |p|
			parentStep.times do
				if (tmp = p.parent) != nil
					p = tmp
				end
			end
			pgsp[p] = true
		end
		pgs = ProcList.independent(pgsp.keys)
	end
	if pgs != nil
		c = ""
		pgs.sort! do |a, b|
			a.startTime <=> b.startTime
		end
		pgs = pgs.select{|item| item.pid.to_i != $$.to_i}
		pidList = []
		if !allChild
			pgs.each do |e|
				pidList.push e.pid
			end
		else
			pgs.each do |e|
				e.each do |f|
					pidList.push f.pid
				end
			end
		end
		if cols != nil
			require 'Yk/escseq'
			Escseq.beIncludedBy String
			i = 0
			hl = ProcList.headLine
			c += hl.method(:yellow).call
			pgs.each do |e|
				c += e.format(cols, orgPgs) do |pg, line|
					if orgPgs.include? pg
						line.replace(line.method(i % 2 == 1 ? :cyan : :green).call)
						i += 1
					end
				end
			end
			if !sendSig && lineNum(cols, c) > rows
				IO.popen "less -R", "w" do |fw|
					fw.write c
				end
			else
				print c
			end
		else
			pidList.each do |pid|
				print pid, "\n"
			end
		end
		if sendSig
			res = nil
			first = true
			if pidList.include? 1
				STDERR.write "Error: cannot send signal to init process\n"
				exit 1
			end
			pidList.each do |pid|
				if !force && res != "ya" 
					case res = "kill #{pid}? <n|na|y|ya>".prompt
					when "na"
						break
					when "y", "ya"
					else
						next
					end
				end
				begin
					Process.kill sendSig, pid
				rescue Errno::ESRCH
					STDERR.write "Process, #{pid} does not exists.\n"
				end
			end
		end
	else
		if cols != nil
			print "process not found\n"
		end
	end

