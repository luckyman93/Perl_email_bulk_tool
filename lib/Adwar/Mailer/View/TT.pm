package Adwar::Mailer::View::TT;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
);

=head1 NAME

Adwar::Mailer::View::TT - TT View for Adwar::Mailer

=head1 DESCRIPTION

TT View for Adwar::Mailer.

=head1 SEE ALSO

L<Adwar::Mailer>

=head1 AUTHOR

Richard Wallman,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
