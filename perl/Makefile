devenv:
	sudo cpanm App::scan_prereqs_cpanfile

cpanfile:
	rm -f cpanfile
	scan-prereqs-cpanfile --ignore=backup > cpanfile

installdeps:
	sudo cpanm --installdeps .

db:
	perl db.pl -a deploy_db -d skud.db
	perl db.pl -a demo_data -d skud.db

rmdb:
	rm skud.db

yancy:
		morbo -l  "http://*:3007" yancy.pl

bot:
	morbo -l  "http://*:3005" bot_embedded.pl

build:
	# Only for running at armhf hosts
	docker build -t pavelsr/fabkey .

push:
	# Only for running at armhf hosts
	docker push pavelsr/fabkey
