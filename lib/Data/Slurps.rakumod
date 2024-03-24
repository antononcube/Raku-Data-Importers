unit module Data::Slurps;

use HTTP::Tiny;
use Image::Markup::Utilities;
use JSON::Fast;
use URI;

#============================================================
# Text utilities
#============================================================

#-----------------------------------------------------------
sub text-stats(Str:D $txt) is export {
    <chars words lines> Z=> [$txt.chars, $txt.words.elems, $txt.lines.elems]
}

#============================================================
# HTML import
#============================================================

#-----------------------------------------------------------

sub is-url(Str $url -->Bool) {
    try {
        return so(URI.new($url).grammar.parse-result<URI-reference><URI> // False);
    }
    if !$ { return False; }
    return False;
}

#-----------------------------------------------------------
sub strip-html(Str $html) returns Str {

    my $res = $html
            .subst(/'<style'.*?'</style>'/, :g)
            .subst(/'<script'.*?'</script>'/, :g)
            .subst(/'<'.*?'>'/, :g)
            .subst(/'&lt;'.*?'&gt;'/, :g)
            .subst(/'&nbsp;'/, ' ', :g)
            .subst(/[\v\s*] ** 2..*/, "\n\n", :g);

    return $res;
}

#-----------------------------------------------------------
proto sub import-url(Str $url, |) is export {*}

multi sub import-url(Str $url, $format, *%args) {
    return import-url($url, :$format, |%args);
}

multi sub import-url(Str $url, :$format is copy = Whatever, *%args) {

    # Process format
    if $format.isa(Whatever) {
        $format = do given $url {
            when $_ ~~ /:i '.csv' $ / { 'csv' }
            when $_ ~~ /:i '.json' $ / { 'json' }
            when $_ ~~ /:i '.txt' | '.text' $ / { 'text' }
            when $_ ~~ /:i '.' [jpg | jpeg | png] $ / { 'image' }
            when $_ ~~ /:i '.xml' $ / { 'xml' }
            default { 'html' }
        }
    }

    if $format ~~ Str:D {
        $format = do given $format {
            when $_ ∈ <txt text> { 'plaintext' }
            when $_ ∈ <img image png jpg jpeg> { 'image' }
            when $_ ∈ <markdown-image md-image> { 'md-image' }
            default { $format }
        }
    }

    my @expectedFormats = <csv html image json md-image plaintext text xml>;
    die "The argument \$format is expected to be Whatever or one of: '{ @expectedFormats.join(', ') }'"
    unless $format ~~ Str:D && $format.lc ∈ @expectedFormats;
    $format = $format.lc;

    # Delegate image ingestion
    if $format ∈ <image md-image> {
        if $format eq 'image' { $format = 'base_64'; }
        return image-import($url, :$format);
    }

    # Import URL content
    my $content = HTTP::Tiny.new.get($url)<content>.decode;

    # Process
    return do given $format {
        when 'csv' {
            my $csv-file = $*TMPDIR.child("temp-{ (^10).pick(12).join }.csv");
            $csv-file.spurt($content);
            return import-file($csv-file, format => 'csv', |%args);
        }
        when $_ eq 'plaintext' {
            $content .= subst(/ \v+ /, "\n", :g);
            strip-html($content);
        }
        when 'json' {
            return from-json($content);
        }
        when 'xml' {
            die 'XML import is not implemented yet.';
        }
        default {
            # Here goes 'asis' also
            $content
        }
    }
}

#-----------------------------------------------------------
multi sub slurp($input where $input.&is-url, :$format = Whatever, *%args) is export {
    return import-url($input, :$format, |%args);
}

#============================================================
# File import
#============================================================
proto sub import-file($file, |) is export {*}

multi sub import-file(Str $file, :$format is copy = Whatever, *%args) {
    return import-file($file.IO, :$format, |%args);
}

multi sub import-file(IO::Path $file, :$format is copy = Whatever, *%args) {
    # Process format
    if $format.isa(Whatever) {
        $format = do given $file {
            when $_ ~~ /:i '.json' $ / { 'json' }
            when $_ ~~ /:i '.txt' | '.text' $ / { 'text' }
            when $_ ~~ /:i '.html' $ / { 'plaintext' }
            when $_ ~~ /:i '.xml' $ / { 'xml' }
            when $_ ~~ /:i '.csv' $ / { 'csv' }
            when $_ ~~ /:i '.' [jpg | jpeg | png] $ / { 'image' }
            default { 'asis' }
        }
    }

    if $format ~~ Str:D {
        $format = do given $format {
            when $_ ∈ <txt text> { 'plaintext' }
            when $_ ∈ <img image png jpg jpeg> { 'image' }
            when $_ ∈ <markdown-image md-image> { 'md-image' }
            default { $format }
        }
    }

    my @expectedFormats = <csv html image json md-image plaintext text xml>;
    die "The argument \$format is expected to be Whatever or one of: '{ @expectedFormats.join(', ') }'"
    unless $format ~~ Str:D && $format.lc ∈ @expectedFormats;
    $format = $format.lc;

    # Ingest
    return do given $format {
        when $_ ∈ <image md-image> {
            return image-import($file, :$format, |%args);
        }
        when 'json' {
            return to-json(slurp($file));
        }
        when 'csv' {
            try {
                use Text::CSV;
                return csv(in => $file, |%args);
            }
            if $! {
                note $!.^name;
                die 'Cannot import CSV file. Is "Text::CSV" installed?';
            }
        }
        when $_ ∈ <plaintext text txt asis> {
            return slurp($file);
        }
        default {
            die "Do not know what to do with the specified format.";
        }
    }
}

#-----------------------------------------------------------
multi sub slurp($input where $input.IO.e, :$format!) is export {
    return import-file($input, :$format);
}

#============================================================
# Image import
#============================================================

#============================================================
# CSV import
#============================================================
