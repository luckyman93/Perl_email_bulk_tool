#!/bin/bash
export SMTP_API_KEY="1234"
export SMTP_SENDER="Adwar <noreply@adwar.com>"
export SMTP_API_URI="https://api.smtp2go.com/v3/email/send"
export MEDIA_HOME=/tmp
export MEDIA_BASEURL=http://sandbox.adwar.com/media/adverts

./script/adwar_mailer_server.pl -k -r -d -p 3001
