use v6.d;

unit module Data::Exporters::HarwellBoeing;

#| Export sparse matrix data into Harwell–Boeing matrix format file.
our proto sub export($file, $data) is export {*}
#= Used for exchanging and storing sparse matrices.
#= Plain text format.
#= File format of the Harwell–Boeing collection of standard test matrices.
#= The three-letter file extension encodes matrix properties that are also represented in the file.
#= The first letter of the file extension encodes the data type: "r" (real), "c" (complex), or "p" (pattern).
#= The second letter denotes the symmetry property: "s" (symmetric), "u" (unsymmetric), "h" (Hermitian), "z" (skew-symmetric), or "r" (rectangular).
#= The third letter of the file extension is either "a" (assembled) or "e" (elemental unassembled).
#= Stores matrices in a sparse representation.
#= Developed in 1992 by Iain Duff, Roger Grimes, and John Lewis.

multi sub export(Str:D $file, $data) {
    if $file.IO.d {
        die "The first argument should be a file name (not an existing directory.)"
    } else {
        return export($file.IO, $data);
    }
}

sub to-triplet($row) {
    if $row ~~ Associative {
        my $has-i = $row{'i'}:exists;
        my $has-j = $row{'j'}:exists;
        die 'Dataset records are expected to have keys <i j>.'
        unless $has-i && $has-j;
        my $has-x = $row{'x'}:exists;
        return [$row{'i'}, $row{'j'}, ($has-x ?? $row{'x'} !! 1)];
    }

    die 'Each matrix record is expected to be list-like with at least 2 elements.'
    unless $row ~~ Positional && $row.elems >= 2;

    return [$row[0], $row[1], ($row.elems >= 3 ?? $row[2] !! 1)];
}

sub fmt-int-lines(@values, Int:D $width) {
    my $per-line = (80 div $width) max 1;
    my $fmt = '%' ~ $width ~ 'd';

    my @lines;
    my $i = 0;
    while $i < @values.elems {
        my $end = ($i + $per-line - 1) min (@values.elems - 1);
        my @batch = @values[$i .. $end];
        @lines.push(@batch.map({ sprintf($fmt, $_) }).join(''));
        $i += $per-line;
    }
    return @lines;
}

sub fmt-real-lines(@values, Int:D $width = 26, Int:D $prec = 16) {
    my $per-line = (80 div $width) max 1;
    my $fmt = '%' ~ $width ~ '.' ~ $prec ~ 'E';

    my @lines;
    my $i = 0;
    while $i < @values.elems {
        my $end = ($i + $per-line - 1) min (@values.elems - 1);
        my @batch = @values[$i .. $end];
        @lines.push(@batch.map({ sprintf($fmt, .Numeric) }).join(''));
        $i += $per-line;
    }
    return @lines;
}

multi sub export(IO::Path:D $file, $data) {
    die 'The argument $data is expected to be a list-like collection.'
    unless $data ~~ (Array:D | List:D | Seq:D);

    my @triplets = $data.map({ to-triplet($_) }).Array;
    die 'Cannot export an empty matrix.'
    if @triplets.elems == 0;

    my Bool $is-complex = @triplets.grep({ $_[2] ~~ Complex }).elems > 0;
    my Bool $is-pattern = !$is-complex && @triplets.grep({ !($_[2] ~~ Numeric) }).elems > 0;

    my @norm;
    for @triplets -> $t {
        my $i = $t[0].Int;
        my $j = $t[1].Int;
        die 'Row and column indices must be positive integers.'
        unless $i >= 1 && $j >= 1;

        my $x = $t[2];
        if $is-complex {
            die 'All values must be Complex when at least one Complex value is present.'
            unless $x ~~ Complex;
        } elsif !$is-pattern {
            die 'All values must be numeric for real-valued export.'
            unless $x ~~ Numeric;
        }
        @norm.push([$i, $j, $x]);
    }

    @norm = @norm.sort({
        $^a[1] <=> $^b[1] || $^a[0] <=> $^b[0]
    });

    my $nrow = @norm.map(*[0]).max;
    my $ncol = @norm.map(*[1]).max;
    my @colptr = (1);
    my @rowind;
    my @vals;
    my $k = 0;
    for 1 .. $ncol -> $col {
        while $k < @norm.elems && @norm[$k][1] == $col {
            @rowind.push(@norm[$k][0]);
            @vals.push(@norm[$k][2]) unless $is-pattern;
            $k++;
        }
        @colptr.push(@rowind.elems + 1);
    }
    my $nnzero = @rowind.elems;

    my $max-ptr = @colptr.max // 1;
    my $max-ind = @rowind.max // 1;
    my $ptr-width = ($max-ptr.Str.chars max 5);
    my $ind-width = ($max-ind.Str.chars max 5);

    my $ptrfmt = "({ (80 div $ptr-width) max 1 }I{$ptr-width})";
    my $indfmt = "({ (80 div $ind-width) max 1 }I{$ind-width})";
    my $valfmt = $is-pattern ?? '' !! '(3E26.16)';

    my @ptr-lines = fmt-int-lines(@colptr, $ptr-width);
    my @ind-lines = fmt-int-lines(@rowind, $ind-width);
    my @val-lines;
    if !$is-pattern {
        if $is-complex {
            my @flat = @vals.map({ .re, .im }).flat;
            @val-lines = fmt-real-lines(@flat);
        } else {
            @val-lines = fmt-real-lines(@vals);
        }
    }

    my $ptrcrd = @ptr-lines.elems;
    my $indcrd = @ind-lines.elems;
    my $valcrd = @val-lines.elems;
    my $rhscrd = 0;
    my $totcrd = 4 + $ptrcrd + $indcrd + $valcrd + $rhscrd;

    my $mxtype = $is-pattern ?? 'PUA' !! ($is-complex ?? 'CUA' !! 'RUA');

    my $title = 'Created by Data::Exporters::HarwellBoeing';
    my $key = 'RakuHB';

    my @header = (
        sprintf('%-72s%-8s', $title, $key),
        sprintf('%14d%14d%14d%14d%14d', $totcrd, $ptrcrd, $indcrd, $valcrd, $rhscrd),
        sprintf('%-3s%11d%14d%14d%14d', $mxtype, $nrow, $ncol, $nnzero, 0),
        sprintf('%-16s%-16s%-20s%-20s', $ptrfmt, $indfmt, $valfmt, '')
    );

    my $content = (|@header, |@ptr-lines, |@ind-lines, |@val-lines).join("\n") ~ "\n";
    return so spurt($file, $content);
}
