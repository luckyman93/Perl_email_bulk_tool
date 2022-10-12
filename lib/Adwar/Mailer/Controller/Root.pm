package Adwar::Mailer::Controller::Root;
use Moose;
use namespace::autoclean;

use DateTime;
use File::Copy qw/copy/;
use File::Path qw/make_path/;
use JSON;
use LWP;
use MIME::Base64;
use Text::CSV;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

Adwar::Mailer::Controller::Root - Root Controller for Adwar::Mailer

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Do nothing but display the template
    $c->stash->{template} = 'index.tt2';
}

=head2 send_email

=cut

sub send_email : Local Args(0) {
    my ( $self, $c ) = @_;

    my $list = $c->request->upload('csv_file');
    my $image = $c->request->upload('image_file');
    my $subject = $c->request->param('subject');
    my $uri = $c->request->param('link_uri');

    if (not $subject) {
        $c->stash({ error => 'Missing subject line' });
        $c->detach('/index');
    }

    # Copy the image file into a new directory
    my $clean_filename = store_file( $c );
    my $dt = DateTime->now();
    my $image_uri = sprintf '%s/%s/%02d/%02d/%s',
       $c->config->{Adwar}{base_uri},
       $dt->year,
       $dt->month,
       $dt->day,
       $clean_filename,
       ;

    # Build HTML version
    my $bodytext = $c->view('TT')->render(
        $c,
        'email.html.tt2',
        {
            image_filename => $clean_filename,
            image_link     => $c->req->param('link_uri'),
        }
    );

    # Build plaintext version
    my $plaintext = $c->view('TT')->render(
        $c,
        'email.plain.tt2',
        {
            image_filename => $image->filename,
            image_uri      => $image_uri,
            image_link     => $c->req->param('link_uri'),
        }
    );

    # Create common JSON data for posting to SMTP2Go
    my $json_data = {
        api_key     => $c->config->{SMTP2Go}{API_key},
        sender      => $c->config->{SMTP2Go}{sender},
        subject     => $subject,
        html_body   => $bodytext,
        text_body   => $plaintext,
        inlines     => [
            { filename => $clean_filename, fileblob => encode_base64 $image->slurp },
        ],
    };

    my $csv = Text::CSV->new( { binary=>1 } );

    while ( my $row = $csv->getline($list->fh) ) {
        # Rough email regex
        next unless $row->[2] =~ /.+@.+\..+/;

        my $data = smtp2go_poster( $c, {
            clean_filename => $clean_filename,
            image_uri => $image_uri,
            json_data => $json_data,
            recipients => [ $row->[2] ],
        });

        push @{$c->stash->{results}}, $data;
    }
}

=head2 send_batch

Similar to send_email, but returns JSON

=cut

sub send_batch : Local Args(0) {
    my ( $self, $c ) = @_;

    my @list = split(/\r?\n/, $c->request->param('recipients'));
    my $image = $c->request->upload('image_file');
    my $subject = $c->request->param('subject');
    my $uri = $c->request->param('link_uri');

    if (not $subject) {
        $c->stash({ error => 'Missing subject line' });
        $c->detach('/index');
    }

    # Copy the image file into a new directory
    my $clean_filename = store_file( $c );
    my $dt = DateTime->now();
    my $image_uri = sprintf '%s/%s/%02d/%02d/%s',
       $c->config->{Adwar}{base_uri},
       $dt->year,
       $dt->month,
       $dt->day,
       $clean_filename,
       ;

    # Build HTML version
    my $bodytext = $c->view('TT')->render(
        $c,
        'email.html.tt2',
        {
            image_filename => $clean_filename,
            image_link     => $c->req->param('link_uri'),
        }
    );

    # Build plaintext version
    my $plaintext = $c->view('TT')->render(
        $c,
        'email.plain.tt2',
        {
            image_filename => $image->filename,
            image_uri      => $image_uri,
            image_link     => $c->req->param('link_uri'),
        }
    );

    # Create common JSON data for posting to SMTP2Go
    my $json_data = {
        api_key     => $c->config->{SMTP2Go}{API_key},
        sender      => $c->config->{SMTP2Go}{sender},
        subject     => $subject,
        html_body   => $bodytext,
        text_body   => $plaintext,
        inlines     => [
            { filename => $clean_filename, fileblob => encode_base64 $image->slurp },
        ],
    };

    my $results;
    foreach my $entry ( @list ) {
        chomp $entry;
        my (undef, undef, $email, undef) = split ',', $entry;

        # Rough email regex
        next unless $email =~ /.+@.+\..+/;

        my $data = smtp2go_poster( $c, {
            clean_filename => $clean_filename,
            image_uri => $image_uri,
            json_data => $json_data,
            recipients => [ $email ],
        });

        push @{$results}, $data;
    }

    $c->response->body( encode_json {
        results => $results,
    });
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head2 store_file

=cut

sub store_file : Private {
    my ($c) = @_;

    my $image = $c->request->upload('image_file');

    my $dt = DateTime->now();
    my $base = sprintf '%s/%s/%02d/%02d', $c->config->{Adwar}{home}, $dt->year, $dt->month, $dt->day;
    my $clean_filename = $image->filename;
    $clean_filename =~ s/[^[:alnum:]\.]/_/smxg;
    my $image_path = sprintf '%s/%s', $base, $image->filename;
    make_path( $base );
    copy( $image->tempname, $image_path );

    return $clean_filename;
}

=head2 smtp2go_poster

=cut

sub smtp2go_poster : Private {
    my ($c, $data) = @_;

    my $image = $c->request->upload('image_file');

    # Build HTML version
    my $bodytext = $c->view('TT')->render(
        $c,
        'email.html.tt2',
        {
            image_filename => $data->{clean_filename},
            image_link     => $c->req->param('link_uri'),
        }
    );

    # Build plaintext version
    my $plaintext = $c->view('TT')->render(
        $c,
        'email.plain.tt2',
        {
            image_filename => $image->filename,
            image_uri      => $data->{image_uri},
            image_link     => $c->req->param('link_uri'),
        }
    );

    my $lwp = LWP::UserAgent->new;

    my $results;
    foreach my $email ( @{ $data->{recipients} } ) {
        # Rough email regex
        next unless $email =~ /.+@.+\..+/;

        $data->{json_data}{'to'} = [ $email ];
        my $req = HTTP::Request->new( 'POST', $c->config->{SMTP2Go}{API_URI} );
        $req->header( 'Content-Type' => 'application/json' );
        $req->content( encode_json $data->{json_data} );
        my $res = $lwp->request( $req );

        my $data = {
            email => $email,
            success => 0,
            message => sprintf 'Unknown failure: %d=%s', $res->code, $res->decoded_content
        };

        if ( $res->is_success ) {
            my $resdata = decode_json $res->decoded_content;
            if ( $resdata->{data}{succeeded} ) {
                $data->{success} = 1;
                $data->{message} = $resdata->{data}{email_id};
            }
            else {
                # Properly display the error instead of just using the default "Unknown failure"
            }
        }

        push @{$results}, $data;
    }

    return $results;
}

=head1 AUTHOR

Richard Wallman,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
