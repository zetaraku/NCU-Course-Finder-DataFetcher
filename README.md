# NCU-Course-Finder-DataFetcher
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fzetaraku%2FNCU-Course-Finder-DataFetcher.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fzetaraku%2FNCU-Course-Finder-DataFetcher?ref=badge_shield)


Introduction
------------

This is the back end of the project [NCU-Course-Finder](https://github.com/zetaraku/NCU-Course-Finder).

It is used to fetch the course data (and upload them to your server).

It uses [NCU Course Schedule Planning System](https://course.ncu.edu.tw/) internal API to get the course data,

and [NCU API](https://github.com/NCU-CC/API-Documentation) (NCU student & staff only) to get some extra data (course type).


Preparation
-----------

Make a copy of `_settings.sh.example` as `_settings.sh`.

To use the NCU API, you need to obtain the [NCU OAuth](https://api.cc.ncu.edu.tw/manage).

Put your NCU API Token into the `NCU_API_TOKEN` field in `_settings.sh`.


Updating local data
-------------------

Use `./update.sh` to update the course data and counts.

(Maybe once per hour.)

Use `./update.sh 1` to update the base data and fill the extra info of the courses.

(Maybe once per day. Don't do it too often, NCU API have access limit!)


Uploading data to server
------------------------

You need to have the command-line tool `lftp` beforehand.

On Ubuntu, you can use `sudo apt install lftp` to install.

After filling the required infomation in `_settings.sh`,

you can use `./upload.sh` to upload your data to the server.


License
-------

Copyright © 2017, Raku Zeta. Licensed under the MIT license.


## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fzetaraku%2FNCU-Course-Finder-DataFetcher.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fzetaraku%2FNCU-Course-Finder-DataFetcher?ref=badge_large)