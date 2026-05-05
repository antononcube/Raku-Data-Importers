use v6.d;

unit module Data::Importers::HarwellBoeing;

#| Import file with matrix in Harwell–Boeing matrix.
#| Returns a coordinate list (COO) of the (sparse) matrix.
our proto sub import(
    $file,                   #= Name of file in Harwell-Boeing format
    Bool:D :$dataset = False, #= Should the result be returned as dataset or not
    ) is export {*}
#= Used for exchanging and storing sparse matrices.
#= Plain text format.
#= File format of the Harwell–Boeing collection of standard test matrices.
#= The three-letter file extension encodes matrix properties that are also represented in the file.
#= The first letter of the file extension encodes the data type: "r" (real), "c" (complex), or "p" (pattern).
#= The second letter denotes the symmetry property: "s" (symmetric), "u" (unsymmetric), "h" (Hermitian), "z" (skew-symmetric), or "r" (rectangular).
#= The third letter of the file extension is either "a" (assembled) or "e" (elemental unassembled).
#= Stores matrices in a sparse representation.
#= Developed in 1992 by Iain Duff, Roger Grimes, and John Lewis.

sub parse-fortran-format(Str:D $fmt) {
    return Nil unless $fmt.trim.chars > 0;

    my $f = $fmt.trim;
    $f ~~ s/^\(//;
    $f ~~ s/\)$//;
    $f ~~ s:g/\s+//;

    # Optional scale factor in forms like "1P,3E20.13".
    if $f ~~ /^ [ '+' | '-' ]? \d+ <[pP]> ',' (.*) $ / {
        $f = ~$0;
    }

    if $f ~~ /^ (\d+)? (<[iIfFeEdDgG]>) (\d+) [ '.' (\d+) ]? [ <[eE]> [ '+' | '-' ]? \d+ ]? $ / {
        return {
            count => ($0 // 1).Int,
            kind  => ~$1.uc,
            width => $2.Int,
            prec  => ($3 // 0).Int
        };
    }

    Nil
}

sub read-fixed-width-values(@lines, Str:D $fmt, Int:D $expected, :$integer = False, :$real = False) {
    my $parsed = parse-fortran-format($fmt);

    my @tokens;
    if $parsed.defined && $parsed<width> > 0 {
        my $w = $parsed<width>;
        for @lines -> $line {
            my $pos = 0;
            while $pos < $line.chars {
                my $chunk = $line.substr($pos, $w).trim;
                @tokens.push($chunk) if $chunk.chars > 0;
                $pos += $w;
            }
        }
    } else {
        @tokens = @lines.join(' ').words;
    }

    die "Insufficient data fields; expected $expected values, got {@tokens.elems}."
    if @tokens.elems < $expected;

    @tokens = @tokens[0 ..^ $expected];

    return @tokens.map({
        if $integer {
            .Int
        } elsif $real {
            .subst('d', 'E', :g).subst('D', 'E', :g).Numeric
        } else {
            $_
        }
    });
}

multi sub import(IO::Path:D $file, Bool:D :$dataset = False) {
    my @lines = $file.lines;
    die "Harwell-Boeing file '$file' is too short." if @lines.elems < 4;

    my @line2 = @lines[1].words;
    die "Invalid Harwell-Boeing header line 2 in '$file'."
    if @line2.elems < 5;

    my ($totcrd, $ptrcrd, $indcrd, $valcrd, $rhscrd) = @line2[^5]>>.Int;

    my @line3 = @lines[2].words;
    die "Invalid Harwell-Boeing header line 3 in '$file'."
    if @line3.elems < 5;

    my $mxtype = @line3[0].uc;
    my ($nrow, $ncol, $nnzero, $neltvl) = @line3[1..4]>>.Int;

    die "Unsupported Harwell-Boeing matrix type '$mxtype' in '$file'."
    unless $mxtype.chars == 3 && $mxtype ~~ /^ <[RCP]> <[SUHZR]> <[AE]> $ /;

    die "Elemental (unassembled) Harwell-Boeing matrices are not supported yet."
    if $mxtype.substr(2, 1) eq 'E';

    my @line4 = @lines[3].words;
    die "Invalid Harwell-Boeing header line 4 in '$file'."
    if @line4.elems < 2;

    my $ptrfmt = @line4[0];
    my $indfmt = @line4[1];
    my $valfmt = @line4.elems >= 3 ?? @line4[2] !! '';

    my $offset = 4;
    my @ptr-lines = @lines[$offset ..^ ($offset + $ptrcrd)];
    $offset += $ptrcrd;

    my @ind-lines = @lines[$offset ..^ ($offset + $indcrd)];
    $offset += $indcrd;

    my @val-lines = @lines[$offset ..^ ($offset + $valcrd)];
    $offset += $valcrd;

    my @colptr = read-fixed-width-values(@ptr-lines, $ptrfmt, $ncol + 1, :integer);
    my @rowind = read-fixed-width-values(@ind-lines, $indfmt, $nnzero, :integer);

    my @values;
    given $mxtype.substr(0, 1) {
        when 'P' {
            @values = 1 xx $nnzero;
        }
        when 'R' {
            @values = read-fixed-width-values(@val-lines, $valfmt, $nnzero, :real);
        }
        when 'C' {
            my @reim = read-fixed-width-values(@val-lines, $valfmt, 2 * $nnzero, :real);
            @values = (for ^$nnzero -> $k {
                Complex.new(@reim[2 * $k], @reim[2 * $k + 1])
            });
        }
        default {
            die "Unsupported data type in matrix type '$mxtype'.";
        }
    }

    # Import
    my @triplets;
    for 1 .. $ncol -> $j {
        my $start = @colptr[$j - 1];
        my $end = @colptr[$j] - 1;
        next if $end < $start;

        for $start .. $end -> $k {
            my $i = @rowind[$k - 1];
            my $x = @values[$k - 1];
            @triplets.push([$i, $j, $x]);
        }
    }

    # Format
    if $dataset {
        return @triplets.map({ <i j x>.Array Z=> $_.Array })».Hash.List;
    }
    return @triplets;
}

multi sub import(Str:D $file, Bool:D :$dataset = False) {
    if $file.IO.e {
        return import($file.IO, :$dataset);
    } else {
        die "Cannot find a file named $file."
    }
}