use strict;
use warnings;

use Adwar::Mailer;

my $app = Adwar::Mailer->apply_default_middlewares(Adwar::Mailer->psgi_app);
$app;

