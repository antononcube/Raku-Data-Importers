# Data::Importers

[![Actions Status](https://github.com/antononcube/Raku-Data-Importers/actions/workflows/linux.yml/badge.svg)](https://github.com/antononcube/Raku-Data-Importers/actions)
[![Actions Status](https://github.com/antononcube/Raku-Data-Importers/actions/workflows/macos.yml/badge.svg)](https://github.com/antononcube/Raku-Data-Importers/actions)

[![](https://raku.land/zef:antononcube/Data::Importers/badges/version)](https://raku.land/zef:antononcube/Data::Importers)
[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)

## In brief

This repository is for a Raku package for the import and export of different types of data
from both URLs and files. Automatically deduces the data type from extensions.

**Remark:** The built-in subs `slurp` and `spurt` are overloaded by definitions of this package.
The corresponding functions `data-import` and `data-export` can be also used.

The format of the data of the URLs or files can be specified with the named argument "format".
If `format => Whatever` then the format of the data is implied by the extension of the given URL or file name.

(Currently) the recognized formats are: CSV, HTML, JSON, Image (png, jpeg, jpg), PDF, Plaintext, Text, XML.

The subs `slurp` and `data-import` can work with:

- CSV & TSV files if ["Text::CSV"](https://raku.land/zef:Tux/Text::CSV), [HMBp1], is installed

- PDF files if ["PDF::Extract"](https://raku.land/zef:Tux/PDF::Extract), [SRp1], is installed

The subs `spurt` and `data-export` can work with CSV & TSV files if ["Text::CSV"](https://raku.land/zef:Tux/Text::CSV), [HMBp1], is installed

**Remark:** Since "Text::CSV" is a "heavy" to install package, it is not included in the dependencies of this one.

**Remark:** Similarly, "PDF::Extract" requires additional, non-Raku installation, and it targets only macOS (currently.)
That is why it is not included in the dependencies of "Data::Importers".

----

## Installation

From Zef' ecosystem:

```
zef install Data::Importers
```

From GitHub:

```
zef install https://github.com/antononcube/Raku-Data-Importers.git
```

-----

## File examples

In order to use the `slurp` definitions of this package the named argument "format" 
has to be specified:  

### JSON file

```perl6
use Data::Importers;

slurp($*CWD ~ '/resources/simple.json', format => 'json')
```
```
# {name => ingrid, value => 1}
```

Instead of `slurp` the function `data-import` can be used (no need to use "format"):

```perl6
data-import($*CWD ~ '/resources/simple.json')
```
```
# {name => ingrid, value => 1}
```

### CSV file

```perl6
slurp($*CWD ~ '/resources/simple.csv', format => 'csv', headers => 'auto')
```
```
# [{X1 => 1, X2 => A, X3 => Cold} {X1 => 2, X2 => B, X3 => Warm} {X1 => 3, X2 => C, X3 => Hot}]
```

-----

## URLs examples

## JSON URLs

Import a JSON file:

```perl6
my $url = 'https://raw.githubusercontent.com/antononcube/Raku-LLM-Prompts/main/resources/prompt-stencil.json';

my $res = data-import($url, format => Whatever);

$res.WHAT;
```
```
# (Hash)
```

Here is the deduced type:

```perl6
use Data::TypeSystem;

deduce-type($res);
```
```
# Struct([Arity, Categories, ContributedBy, Description, Keywords, Name, NamedArguments, PositionalArguments, PromptText, Topics, URL], [Int, Hash, Str, Str, Array, Str, Array, Hash, Str, Hash, Str])
```

Using `slurp` instead of `data-import`:

```perl6
slurp($url)
```
```
# {Arity => 1, Categories => {Function Prompts => False, Modifier Prompts => False, Personas => False}, ContributedBy => Anton Antonov, Description => Write me!, Keywords => [], Name => Write me!, NamedArguments => [], PositionalArguments => {$a => VAL}, PromptText => -> $a='VAL' {"Something over $a."}, Topics => {AI Guidance => False, Advisor Bots => False, Character Types => False, Chats => False, Computable Output => False, Content Derived from Text => False, Education => False, Entertainment => False, Fictional Characters => False, For Fun => False, General Text Manipulation => False, Historical Figures => False, Linguistics => False, Output Formatting => False, Personalization => False, Prompt Engineering => False, Purpose Based => False, Real-World Actions => False, Roles => False, Special-Purpose Text Manipulation => False, Text Analysis => False, Text Generation => False, Text Styling => False, Wolfram Language => False, Writers => False, Writing Genres => False}, URL => None}
```

### Image URL

Import an [image](https://raw.githubusercontent.com/antononcube/Raku-WWW-OpenAI/main/resources/ThreeHunters.jpg):

```perl6
my $imgURL = 'https://raw.githubusercontent.com/antononcube/Raku-WWW-OpenAI/main/resources/ThreeHunters.jpg';

data-import($imgURL, format => 'md-image').substr(^100)
```
```
# ![](data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAUEBAUEAwUFBAUGBgUGCA4JCAcHCBEMDQoOFBEVF
```

**Remark:** Image ingestion is delegated to 
["Image::Markup::Utilities"](https://raku.land/zef:antononcube/Image::Markup::Utilities), [AAp1].
The format value 'md-image' can be used to display images in Markdown files or Jupyter notebooks.

### CSV URL

Here we ingest a CSV file and show a table of a 10-rows sample:

```perl6, results=asis
use Data::Translators;

'https://raw.githubusercontent.com/antononcube/Raku-Data-ExampleDatasets/main/resources/dfRdatasets.csv'
==> slurp(headers => 'auto') 
==> { $_.pick(10).sort({ $_<Package Item> }) }()
==> data-translation(field-names => <Package Item Title Rows Cols>)
```
<table border="1"><thead><tr><th>Package</th><th>Item</th><th>Title</th><th>Rows</th><th>Cols</th></tr></thead><tbody><tr><td>AER</td><td>BenderlyZwick</td><td>Benderly and Zwick Data: Inflation, Growth and Stock Returns</td><td>31</td><td>5</td></tr><tr><td>Ecdat</td><td>Doctor</td><td>Number of Doctor Visits</td><td>485</td><td>4</td></tr><tr><td>Ecdat</td><td>StrikeNb</td><td>Number of Strikes in Us Manufacturing</td><td>108</td><td>3</td></tr><tr><td>Ecdat</td><td>nkill.byCountryYr</td><td>Global Terrorism Database yearly summaries</td><td>206</td><td>46</td></tr><tr><td>HSAUR</td><td>water</td><td>Mortality and Water Hardness</td><td>61</td><td>4</td></tr><tr><td>MASS</td><td>SP500</td><td>Returns of the Standard and Poors 500</td><td>2780</td><td>1</td></tr><tr><td>Stat2Data</td><td>Day1Survey</td><td>First Day Survey of Statistics Students</td><td>43</td><td>13</td></tr><tr><td>Stat2Data</td><td>Putts3</td><td>Hypothetical Putting Data (Short Form)</td><td>5</td><td>4</td></tr><tr><td>asaur</td><td>pharmacoSmoking</td><td>pharmacoSmoking</td><td>125</td><td>14</td></tr><tr><td>openintro</td><td>male_heights</td><td>Sample of 100 male heights</td><td>100</td><td>1</td></tr></tbody></table>


### PDF URL

Here is an example of importing a PDF file into plain text:

```perl6
my $txt = slurp('https://pdfobject.com/pdf/sample.pdf', format=>'text');

say text-stats($txt);
```
```
# (chars => 2851 words => 416 lines => 38)
```

**Remark:** The function `text-stats` is provided by this package, "Data::Importers". 

Here is a sample of the imported text:

```perl6
$txt.lines[^6].join("\n")
```
```
# Sample PDF
# This is a simple PDF file. Fun fun fun.
# Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Phasellus facilisis odio sed mi.
# Curabitur suscipit. Nullam vel nisi. Etiam semper ipsum ut lectus. Proin aliquam, erat eget
# pharetra commodo, eros mi condimentum quam, sed commodo justo quam ut velit.
# Integer a erat. Cras laoreet ligula cursus enim. Aenean scelerisque velit et tellus.
```


-----

## TODO

- [X] DONE Development
  - [X] DONE PDF ingestion
    - [X] DONE Files 
    - [X] DONE URLs
  - [ ] TODO Export to:
    - [X] DONE JSON files
    - [X] DONE text, Markdown, org, HTML, XML files
    - [X] DONE CSV/TSV files
    - [ ] TODO PDF files
    - [ ] TODO Image files
- [ ] TODO Unit tests
  - [ ] TODO PDF ingestion
    - Some initial tests are put in.

----- 

## References

[AAp1] Anton Antonov,
[Image::Markup::Utilities Raku package](https://github.com/antononcube/Raku-Image-Markup-Utilities),
(2023),
[GitHub/antononcube](https://github.com/antononcube).

[HMBp1] H. Merijn Brand,
[Text::CSV Raku package](https://github.com/Tux/CSV),
(2015-2023),
[GitHub/Tux](https://github.com/Tux).

[SRp1] Steve Roe,
[PDF::Extract Raku package](https://github.com/librasteve/raku-PDF-Extract),
(2023),
[GitHub/librasteve](https://github.com/librasteve).   