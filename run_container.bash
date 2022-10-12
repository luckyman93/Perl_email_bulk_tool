#!/usr/bin/env bash

docker run -d -it --env-file $1  \
-v /home/vhosts/adwar.com/media/adverts:/home/vhosts/adwar.com/media/adverts \
--name adwar-marketing \
--network vhosts_default \
--restart unless-stopped \
$2

