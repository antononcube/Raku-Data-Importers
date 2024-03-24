# Data::Importers

## In brief

This repository is for a Raku package for the ingestion of different types of data
from both URLs and files.

**Remark:** The built-in sub `slurp` is overloaded by definitions of this package.
The corresponding function `import` can be also used.

**Remark:** The slurp / import functions can work with CSV files if 
["Text::CSV"](https://raku.land/zef:Tux/Text::CSV), [HMBp1],
is installed. Since "Text::CSV" is a "heavy" to install package, it is not included in the dependencies of this one.

The format of the data of the URLs or files can be specified with the named argument "format".
If `format => Whatever` then the format of the data is implied by the extension of the given URL or file name. 

----

## Installation

From Zef' ecosystem:

```
zef install Data::Importers
```

From GitHub:

```
zef install https://github.com/antononcube/Raku-Data-Slurps.git
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

Instead of `slurp` the function `import` can be used (no need to use "format"):

```perl6
import($*CWD ~ '/resources/simple.json')
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

my $res = import($url, format => Whatever);

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

Using `slurp` instead of `import`:

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

import($imgURL, format => 'md-image').substr(^100)
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
<table border="1"><thead><tr><th>Package</th><th>Item</th><th>Title</th><th>Rows</th><th>Cols</th></tr></thead><tbody><tr><td>AER</td><td>ArgentinaCPI</td><td>Consumer Price Index in Argentina</td><td>80</td><td>2</td></tr><tr><td>Ecdat</td><td>ModeChoice</td><td>Data to Study Travel Mode Choice</td><td>840</td><td>7</td></tr><tr><td>KMsurv</td><td>kidtran</td><td>data from Section 1.7</td><td>863</td><td>6</td></tr><tr><td>MASS</td><td>Aids2</td><td>Australian AIDS Survival Data</td><td>2843</td><td>7</td></tr><tr><td>Stat2Data</td><td>SuicideChina</td><td>Suicide Attempts in Shandong, China</td><td>2571</td><td>11</td></tr><tr><td>boot</td><td>beaver</td><td>Beaver Body Temperature Data</td><td>100</td><td>4</td></tr><tr><td>boot</td><td>motor</td><td>Data from a Simulated Motorcycle Accident</td><td>94</td><td>4</td></tr><tr><td>openintro</td><td>gifted</td><td>Analytical skills of young gifted children</td><td>36</td><td>8</td></tr><tr><td>openintro</td><td>mlb</td><td>Salary data for Major League Baseball (2010)</td><td>828</td><td>4</td></tr><tr><td>robustbase</td><td>hbk</td><td>Hawkins, Bradu, Kass&#39;s Artificial Data</td><td>75</td><td>4</td></tr></tbody></table>


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