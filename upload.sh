#!/bin/bash

source _settings.sh

lftp $USER:$PASSWD@$HOST <<-SCRIPT
	lcd $LOCAL_DIR
	cd $REMOTE_DIR
	mput $FILES
	quit
SCRIPT
