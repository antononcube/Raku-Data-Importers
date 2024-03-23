#!/usr/bin/env raku
use v6.d;

use Data::Slurps;
use Data::Summarizers;
use Data::TypeSystem;

say '=' x 120;
say 'Using import-url';
say '-' x 120;

my $url = 'https://raw.githubusercontent.com/antononcube/Raku-LLM-Prompts/main/resources/prompt-stencil.json';
say import-url($url);

my $url2 = 'https://raw.githubusercontent.com/antononcube/Raku-Data-ExampleDatasets/main/resources/dfRdatasets.csv';
my $data = import-url($url2, headers => 'auto');

say $data.WHAT;
say deduce-type($data);

records-summary($data);

#========================================================================================================================
say '=' x 120;
say 'Using slurp';
say '-' x 120;

say slurp($url);

say '-' x 120;

records-summary slurp($url2, headers => 'auto');
