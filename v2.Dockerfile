FROM ubuntu:20.04

RUN [ "mkdir", "/app"]
RUN [ "touch", "/app/config.ini" ]
RUN [ "sed", "-i", "$ aversion=1.0", "/app/config.ini" ]

