unit module Data::Importers;

use HTTP::Tiny;
use Image::Markup::Utilities;
use JSON::Fast;
use Data::TypeSystem;
use URI;

#============================================================
# Check utilities
#============================================================
# These are taken for "App::Rak" by lizmat.

my $TextCSV;
my $PDFExtract;

# Sane way of quitting
my sub meh($message) is hidden-from-backtrace {
    die $message.ends-with('.' | '?')
            ?? $message
            !! "$message.";
}

# Quit if module not installed
my sub meh-not-installed($module, $feature) is hidden-from-backtrace {
    meh qq:to/MEH/.chomp;
Must have the $module module installed to do $feature.
You can do this by running 'zef install $module'.
MEH
}

# check Text::CSV availability
my sub check-TextCSV(str $name) {
    unless $TextCSV {
        CATCH { meh-not-installed 'Text::CSV', "$name" }
        require Text::CSV;
        $TextCSV := Text::CSV;
    }
}

# check PDF::Extract availability
my sub check-PDFExtract(str $name) {
    unless $PDFExtract {
        CATCH { meh-not-installed 'PDF::Extract', "$name" }
        #require PDF::Extract;
        require PDF::Extract <Extract>;
        $PDFExtract := Extract;
    }
}

#============================================================
# Text utilities
#============================================================

#-----------------------------------------------------------
#| Text statistics routine similar to UNIX's wc.
sub text-stats(Str:D $txt, Bool :p(:$pairs) = True) is export {
    if $pairs {
        <chars words lines> Z=> [$txt.chars, $txt.words.elems, $txt.lines.elems]
    } else {
        [$txt.chars, $txt.words.elems, $txt.lines.elems]
    }
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
sub strip-html(Str $html --> Str) is export {

    my $res = $html
            .subst(/'<style'.*?'</style>'/, :g)
            .subst(/'<script'.*?'</script>'/, :g)
            .subst(/'<'.*?'>'/, :g)
            .subst(/'&lt;'.*?'&gt;'/, :g)
            .subst(/'&nbsp;'/, ' ', :g)
            .subst(/[\v\s*] ** 2..*/, "\n\n", :g)
            .subst(/'JSON.parse("' .*? <!after \\> '")'/, :g);

    return $res;
}

#-----------------------------------------------------------
proto sub import-url(Str $url, |) {*}

multi sub import-url(Str $url, $format, *%args) {
    return import-url($url, :$format, |%args);
}

multi sub import-url(Str $url, :$format is copy = Whatever, *%args) {
    # Extension
    my $ext = do with $url.match(/ '.' (\w+) $/) { $0.Str.lc };

    # Process format
    if $format.isa(Whatever) {
        $format = do given $url {
            when $_ ~~ /:i '.csv' $ / { 'csv' }
            when $_ ~~ /:i '.tsv' $ / { 'tsv' }
            when $_ ~~ /:i '.json' $ / { 'json' }
            when $_ ~~ /:i '.txt' | '.text' $ / { 'text' }
            when $_ ~~ /:i '.pdf' $ / { 'text' }
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

    my @expectedFormats = <asis csv html image json md-image plaintext text tsv xml>;
    die "The argument \$format is expected to be Whatever or one of: '{ @expectedFormats.join(', ') }'"
    unless $format ~~ Str:D && $format.lc ∈ @expectedFormats;
    $format = $format.lc;

    # Delegate image ingestion
    if $format ∈ <image md-image> {
        if $format eq 'image' { $format = 'base_64'; }
        return image-import($url, :$format);
    }

    # Import URL content
    my $content = HTTP::Tiny.new.get($url)<content>;

    # Delegate PDF ingestion
    if $ext eq 'pdf' && $format ne 'asis' {
        my $pdf-file = $*TMPDIR.child("temp-{ (^10).pick(12).join }.pdf");
        $pdf-file.spurt($content);
        return import-file($pdf-file, :$format, |%args);
    }

    # Decode
    $content .= decode;

    # Process
    return do given $format {
        when $_ ∈ <csv tsv> {
            my $csv-file = $*TMPDIR.child("temp-{ (^10).pick(12).join }.$format");
            $csv-file.spurt($content);
            return import-file($csv-file, :$format, |%args);
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

#============================================================
# File import
#============================================================
proto sub import-file($file, |) {*}

multi sub import-file(Str $file, :$format is copy = Whatever, *%args) {
    return import-file($file.IO, :$format, |%args);
}

multi sub import-file(IO::Path $file, :$format is copy = Whatever, *%args) {
    # Extension
    my $ext = do with $file.match(/ '.' (\w+) $/) { $0.Str.lc };

    # Process format
    if $format.isa(Whatever) {
        $format = do given $file {
            when $_ ~~ /:i ['.json' | '.ipynb' | '.vsnb'] $ / { 'json' }
            when $_ ~~ /:i ['.txt' | '.text' | '.org' | '.md' | '.Rmd'] $ / { 'text' }
            when $_ ~~ /:i '.pdf' $ / { 'text' }
            when $_ ~~ /:i '.html' $ / { 'plaintext' }
            when $_ ~~ /:i '.xml' $ / { 'xml' }
            when $_ ~~ /:i '.csv' $ / { 'csv' }
            when $_ ~~ /:i '.tsv' $ / { 'tsv' }
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

    my @expectedFormats = <asis csv html image ipynb json md md-image org plaintext Rmd text tsv xml>;
    die "The argument \$format is expected to be Whatever or one of: '{ @expectedFormats.join(', ') }'"
    unless $format ~~ Str:D && $format.lc ∈ @expectedFormats;
    $format = $format.lc;

    # Ingest
    return do given $format {
        when $_ ∈ <image md-image> {
            return image-import($file, :$format, |%args);
        }
        when 'json' {
            return from-json(slurp($file));
        }
        when 'csv' {
            check-TextCSV('CSV file importing');
            my $csv     := $TextCSV.new();
            return $csv.csv(:$file, |%args);
        }
        when 'tsv' {
            check-TextCSV('TSV file importing');
            my $csv     := $TextCSV.new();
            my %args2 = %( sep => "\t") , %args;
            return $csv.csv(:$file, |%args2);
        }
        when $ext.lc eq 'pdf' && $_ ∈ <plaintext text txt html xml> {
            check-PDFExtract('PDF file importing');
            my $extract = $PDFExtract.new(:$file);
            when $_ ∈ <plaintext text txt> {
                return $extract.text;
            }
            when $_ ∈ <html> {
                return $extract.html;
            }
            when $_ ∈ <xml> {
                return $extract.xml;
            }
            default {
                die "Do not know what to do with the specified format for the a file with extension <pdf>.";
            }

            if $! {
                note $!.^name;
                die 'Cannot import PDF file. Is "PDF::Extract" installed?';
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


#============================================================
# Data import
#============================================================

#| Imports URLs and files.
#| Automatically deduces the data type from extensions.
#| The recognized format types are: CSV, HTML, JSON, Image (png, jpeg, jpg), Markdown, PDF, Org, Plaintext, Rmd, Text, TSV, XML.
#| The format argument can be both named and positional.
#| <$source> -- file or URL.
#| <:$format> -- format of the data; if Whatever the extension is used to determine the format.
proto sub data-import($source, |) is export {*}

multi sub data-import($source, $format, *%args) {
    return data-import($source, :$format, |%args);
}

multi sub data-import($source where $source.IO.e, :$format = Whatever, *%args) {
    return import-file($source, :$format, |%args);
}

multi sub data-import($source where $source.&is-url, :$format = Whatever, *%args) {
    return import-url($source, :$format, |%args);
}

#============================================================
# slurp
#============================================================

multi sub slurp($source where $source.IO.e, :$format!, *%args) is export {
    return import-file($source, :$format, |%args);
}

multi sub slurp($source where $source.&is-url, :$format = Whatever, *%args) is export {
    return import-url($source, :$format, |%args);
}


#============================================================
# File export
#============================================================
proto sub export-file($file, $obj, :$format = Whatever, *%args) {*}

multi sub export-file(Str $file, $obj, :$format is copy = Whatever, *%args) {
    return export-file($file.IO, $obj, :$format, |%args);
}

multi sub export-file(IO::Path $file, $obj, :$format is copy = Whatever, *%args) {
    # Extension
    my $ext = do with $file.match(/ '.' (\w+) $/) { $0.Str.lc };

    # Process format
    if $format.isa(Whatever) {
        $format = do given $file {
            when $_ ~~ /:i ['.json' | '.ipynb' | '.vsnb'] $ / { 'json' }
            when $_ ~~ /:i ['.txt' | '.text' | '.org' | '.md' | '.Rmd'] $ / { 'text' }
            when $_ ~~ /:i '.pdf' $ / { 'text' }
            when $_ ~~ /:i '.html' $ / { 'text' }
            when $_ ~~ /:i '.xml' $ / { 'text' }
            when $_ ~~ /:i '.csv' $ / { 'csv' }
            when $_ ~~ /:i '.tsv' $ / { 'tsv' }
            when $_ ~~ /:i '.' [jpg | jpeg | png] $ / { 'image' }
            default { 'asis' }
        }
    }

    if $format ~~ Str:D {
        $format = do given $format {
            when $_ ∈ <txt text md markdown> { 'plaintext' }
            when $_ ∈ <img image png jpg jpeg> {
                # 'image'
                die 'Image exporting is not supported.';
            }
            when $_ ∈ <markdown-image md-image> {
                # 'md-image'
                die 'Image exporting is not supported.';
            }
            default { $format }
        }
    }

    my @expectedFormats = <asis csv html image ipynb json md md-image org plaintext Rmd text tsv xml>;
    die "The argument \$format is expected to be Whatever or one of: '{ @expectedFormats.join(', ') }'"
    unless $format ~~ Str:D && $format.lc ∈ @expectedFormats;
    $format = $format.lc;

    # Ingest
    return do given $format {
        when 'json' {
            return spurt($file, to-json($obj));
        }
        when 'csv' {
            check-TextCSV('CSV file exporting');
            my $csv     := $TextCSV.new();
            return $csv.csv(:$file, in => $obj, |%args);
        }
        when 'tsv' {
            check-TextCSV('TSV file exporting');
            my $csv     := $TextCSV.new();
            my %args2 = %( sep => "\t") , %args;
            return $csv.csv(:$file, in => $obj |%args2);
        }
        when $_ ∈ <plaintext text txt asis> {
            return spurt($file, $obj);
        }
        default {
            die "Do not know what to do with the specified format.";
        }
    }
}

#============================================================
# Data export
#============================================================

#| Exports objects to files.
#| Automatically deduces the data type from extensions.
#| The recognized format types are: CSV, HTML, JSON, Markdown, Org, Plaintext, Rmd, Text, TSV, XML.
#| The format argument can be both named and positional.
#| <$target> -- File to export to.
#| <$obj> -- object to export.
#| <:$format> -- format of the data; if Whatever the extension is used to determine the format.
proto sub data-export($target, $obj, |) is export {*}

multi sub data-export($target, $obj, $format, *%args) {
    return data-export($target, $obj, :$format, |%args);
}

multi sub data-export($target where ($target.IO.e && $target.IO.f || $target.IO), $obj, :$format = Whatever, *%args) {
    return export-file($target, $obj, :$format, |%args);
}

#============================================================
# spurt
#============================================================

multi sub spurt($target where $target.IO.e, $obj, :$format!, *%args) is export {
    return export-file($target, $obj, :$format, |%args);
}