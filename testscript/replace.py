import os

dir = './scripts'

for root,dirs,files in os.walk(dir):
	for file in files:
		file = './scripts/' + file
		print file
		with open(file,'r') as r:
			lines = r.readlines()

		with open(file,'w') as w:
			for l in lines:
				w.write(l.replace('kill -9','kill -l'))











