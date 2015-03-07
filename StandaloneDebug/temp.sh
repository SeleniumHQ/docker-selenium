# Run from this dir only.
./generate.sh StandaloneDebugFirefox standalone-firefox Firefox 2.45.0
./generate.sh StandaloneDebugChrome standalone-chrome Chrome 2.45.0

cd ../StandaloneDebugFirefox && docker build -t rubytester/standalone-firefox-debug:2.45.0 .
cd ../StandaloneDebugChrome && docker build -t rubytester/standalone-chrome-debug:2.45.0 .

#docker run -d --name standalone-chrome-debug -p 4445:4444 -p 5905:5900 rubytester/standalone-chrome-debug:2.45.0
#open vnc://:secret@$(boot2docker ip):5905
#open http://$(boot2docker ip):4445/wd/hub
#docker stop standalone-chrome-debug
#docker rm !$

#docker run -d --name standalone-firefox-debug -p 4446:4444 -p 5906:5900 rubytester/standalone-firefox-debug:2.45.0
#open vnc://:secret@$(boot2docker ip):5906
#open http://$(boot2docker ip):4446/wd/hub
#docker stop standalone-firefox-debug
#docker rm !$
