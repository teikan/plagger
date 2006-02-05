package Plagger::Plugin::Aggregator::Simple;
use strict;
use base qw( Plagger::Plugin);

use URI;
use XML::Feed;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'aggregator.aggregate' => \&aggregate,
    );
}

sub aggregate {
    my($self, $context) = @_;

    for my $sub ($context->subscription->feeds) {
        my $url = $sub->url;
        $context->log(info => "Fetch $url");
        my $remote = XML::Feed->parse(URI->new($url));

        unless ($remote) {
            $context->log(info => "Parsing $url failed. " . XML::Feed->errstr);
            next;
        }

        my $feed = Plagger::Feed->new;
        $feed->title($remote->title);
        $feed->url($sub->url);
        $feed->link($remote->link);
        $feed->description($remote->tagline);
        $feed->language($remote->language);
        $feed->author($remote->author);
        $feed->updated($remote->modified);

        for my $e ($remote->entries) {
            my $entry = Plagger::Entry->new;
            $entry->title($e->title);
            $entry->author($e->author);
            $entry->tags([ $e->category ]) if $e->category;
            $entry->date( Plagger::Date->rebless($e->issued) );
            $entry->link($e->link);
            $entry->id($e->id);
            $entry->body($e->content->body);

            $feed->add_entry($entry);
        }

        $context->log(info => "Aggregate $url success: " . $feed->count . " entries.");
        $context->update->add($feed);
    }
}

1;
