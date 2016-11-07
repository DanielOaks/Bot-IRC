package Bot::IRC::Seen;
# ABSTRACT: Bot::IRC track when and where users were last seen

use strict;
use warnings;

use DateTime;
use DateTime::Format::Human::Duration;

# VERSION

sub init {
    my ($bot) = @_;
    $bot->load('Store');

    $bot->hook(
        {
            private => 0,
            command => 'PRIVMSG',
        },
        sub {
            my ( $bot, $in ) = @_;
            $in->{time} = time;
            $bot->store->set( lc( $in->{nick} ) => $in );
            return;
        },
    );

    my $duration = DateTime::Format::Human::Duration->new;
    $bot->hook(
        {
            to_me => 1,
            text  => qr/\bseen\s+(?<nick>\S+)/i,
        },
        sub {
            my ( $bot, $in, $m ) = @_;

            my $seen = $bot->store->get( lc( $m->{nick} ) );
            my $text = ($seen)
                ?
                    "$seen->{nick} was last seen in $seen->{forum} " .
                    $duration->format_duration_between(
                        map { DateTime->from_epoch( epoch => $_ ) } $seen->{time}, time
                    ) .
                    " ago saying: \"$seen->{text}\""
                :
                    "Sorry. I haven't seen $m->{nick}.";
            $text = "$in->{nick}: $text" unless ( $in->{private} );

            $bot->reply($text);
        },
    );
}

1;
__END__
=pod

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['Seen'],
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin instructs the bot to remember when and where users
were last seen and to report on this when asked. Commands include:

=head2 seen <nick>

Display last seen information for a given nick.

=for Pod::Coverage init

=cut
