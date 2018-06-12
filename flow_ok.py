#!/usr/local/bin/python
#coding=utf8
'''
Created on Mon Apr  4 19:05:45 CST 2016

@author: meng wei
'''
import re
import subprocess
import os
import time
import sys
import pymssql
from threading import Timer

usercode = {u'j': '1', u'莫': '23', u'刘': '3'}

def mp(fs='//192.168.0.254/调色区/%s' % time.strftime('%m%d'), mpt='/mnt/ts'):
	'''
	mount.cifs filesystem on /mnt/ts default
	'''
	cmdline = 'mount.cifs %s %s -o user="",pass="" >/dev/null 2>&1' % (fs, mpt)
	if os.path.ismount(mpt):
		return 0
	try:
		if not os.path.exists(mpt):
			os.mkdir(mpt)			
	except OSError as e:
		print("Don't mount: %s error reason: %s" % (mpt, e.strerror))
		return 1
	ret = subprocess.call(cmdline, shell=True)
	return ret

def ump(mpt='/mnt/ts'):
	if os.path.ismount(mpt):
		subprocess.call('umount %s' % mpt, shell=True)

def repeatError(content):
	'''
	has repeat flow which write to file tip
	'''
	path = '/mnt/ts'
	filename = '注意_有重复单号.txt'
	file = '%s/%s' % (path, filename)
	if content == {}:
		try:
			if os.path.exists(file):
				os.unlink(file)
		except:
			pass
		return
	try:
		with open(file, 'w') as f:
			f.write(''.join(["{}: {}\r\n".format(key, '<->'.join(value))  for key, value in content.items()]))
	except IOError as e:
		print e.strerror
		return 
	#for key in content.iterkeys():
	#	format = '%s: %s\r\n' % (key, '<->'.join(content[key]))	
	#	f.write(format)

def convert(flow):
	flow = list(set(flow))
	flow.sort()
	return flow

def findSame(flow=[]):
	'''
	find Same flow and return list
	'''
	if flow == list():
		return
	return convert([ i for i in flow if flow.count(i) > 1 ])

def store(flowno):
	'''
	data write to be database
	'''
	conn_info = {'host':'192.168.0.250', 'user':'tt', 'pass':'123', 'db':'ck_digitalStore_album'}
	flow = ''
	try:
		conn = pymssql.connect(conn_info['host'], conn_info['user'], conn_info['pass'], conn_info['db'], charset='utf8') 
		cur = conn.cursor(as_dict=True)
		for u in flowno.iterkeys():
			flo = flowno[u]
			if flo == list():
				continue
			for i in flo:
				flow = "%s,%s%s%s" % (flow, chr(39), i, chr(39))
			sql1 = "SELECT fd_billcode FROM tb_bill_receive WHERE (fd_billcode IN (%s)) AND (fd_workflow_over_yn = 0) AND (fd_workflow_start_yn = 0)"	% flow.lstrip(',')
			cur.execute(sql1)
			flow = ''
			for i in cur:
				flow = "%s,%s%s%s" % (flow, chr(39), i['fd_billcode'], chr(39))
			flow = flow.lstrip(',')
			if flow is '':
				continue
			sql1 = "INSERT INTO tb_workflow_executeLog (fd_billId_refid,fd_workflowId_refid,fd_employeeInfoId_refid,fd_beginTime,fd_endTime,fd_finishedYn,fd_workflow_statusMark) SELECT fd_billId,103,%s,GETDATE(),GETDATE(),1,'★' FROM tb_bill_receive WHERE (fd_billcode IN (%s)) AND (fd_workflow_over_yn = 0) AND (fd_workflow_start_yn = 0)" % (usercode[u], flow.lstrip(','))
			sql2 = "UPDATE tb_bill_receive SET fd_workflowId_refid_ready = 104,fd_workflowId_refid_working = NULL,fd_workflowId_refid_over = 103,fd_workflowId_refid_allOver = 103,fd_workflow_start_yn = 0,fd_workflow_over_yn = 1 WHERE (fd_billcode IN (%s)) AND (fd_workflow_over_yn = 0) AND (fd_workflow_start_yn = 0)" % flow.lstrip(',')
#			print sql1
			#print sql2	
			cur.execute(sql1)	
			cur.execute(sql2)	
			conn.commit()
			#print '%s%s' % ('-'*80, u)
	except pymssql.OperationalError as e:
		print('connection error for database')		
	finally:
		conn.close()

def filterFlow(p):
	'''
	find sample 20060101-000- 
	'''
	flowno = []
	r1 = re.compile(r'^\d{8}-\d{3}-')
	flowno = filter(lambda x:r1.match(x), p)
	flowno = map(lambda x:x[0:12],flowno)
	flowno = convert(flowno)
	return flowno

def checkFlow(path='/mnt/ts'):
	'''
	filter repeat flow number
	'''
	flow = []
	flowdict = {}
	samef = {}
	bakdir = u'新建文件夹'
	for w in usercode:
		p = '%s/%s/%s' % (path, w, bakdir)
		if not os.path.exists(p):
			continue
		pl = os.listdir(p)
		if pl is list():
			return
		flow = filterFlow(pl)
		flowdict[w] = flow
	flow = []
	for f in flowdict.itervalues():
		flow.extend(f)
	sf = findSame(flow)
	if sf is not None:
		for fl in sf:
			samef[fl] = [ key for key in flowdict.iterkeys() if fl in flowdict[key] ]
		repeatError(samef)
		for key in flowdict.iterkeys():
			flowdict.update({key: list(set(flowdict.get(key))-set(sf))})

	return flowdict
#def collectInfo():
					
if __name__ == '__main__':
	#p = '//192.168.0.254/调色区/0401'
	reload(sys)
	sys.setdefaultencoding('utf-8')
	while 1:
		if mp() is not 0:
			time.sleep(60)
			continue
		try:
			flowno = checkFlow()
			store(flowno)
			time.sleep(120)
		except KeyboardInterrupt as e:
			print 'program intrurrpt'
			exit()
	ump()
