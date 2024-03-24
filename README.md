# Data::Slurps

## In brief

This repository is for a Raku package for the ingestion of different types of data
from both URLs and files.

**Remark:** The built-in sub `slurp` is overloaded by definitions of this package.
The corresponding functions `import-url` and `import-file` can be also used.

**Remark:** The slurp / import functions can work with CSV files if 
["Text::CSV"](https://raku.land/zef:Tux/Text::CSV), [HMBp1],
is installed. Since "Text::CSV" is a "heavy" to install package, it is not included in the dependencies of this one.

The format of the data of the URLs or files can be specified with the named argument "format".
If `format => Whatever` then the format of the data is implied by the extension of the given URL or file name. 

----

## Installation

From Zef' ecosystem:

```
zef install Data::Slurps
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
use Data::Slurps;

slurp($*CWD ~ '/resources/simple.json', format => 'json')
```
```
# {name => ingrid, value => 1}
```

Instead of `slurp` the function `import-file` can be used (no need to use "format"):

```perl6
import-file($*CWD ~ '/resources/simple.json')
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

my $res = import-url($url, format => Whatever);

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

Using `slurp` instead of `import-url`:

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

import-url($imgURL, format => 'md-image').substr(^100)
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
<table border="1"><thead><tr><th>Package</th><th>Item</th><th>Title</th><th>Rows</th><th>Cols</th></tr></thead><tbody><tr><td>COUNT</td><td>lbw</td><td>lbw</td><td>189</td><td>10</td></tr><tr><td>Ecdat</td><td>Workinghours</td><td>Wife Working Hours</td><td>3382</td><td>12</td></tr><tr><td>HSAUR</td><td>polyps3</td><td>Familial Andenomatous Polyposis</td><td>22</td><td>5</td></tr><tr><td>HistData</td><td>GaltonFamilies</td><td>Galton&#39;s data on the heights of parents and their children, by child</td><td>934</td><td>8</td></tr><tr><td>carData</td><td>Robey</td><td>Fertility and Contraception</td><td>50</td><td>3</td></tr><tr><td>datasets</td><td>USAccDeaths</td><td>Accidental Deaths in the US 1973-1978</td><td>72</td><td>2</td></tr><tr><td>datasets</td><td>longley</td><td>Longley&#39;s Economic Regression Data</td><td>16</td><td>7</td></tr><tr><td>fpp2</td><td>elecdaily</td><td>Half-hourly and daily electricity demand for Victoria, Australia, in 2014</td><td>365</td><td>3</td></tr><tr><td>mosaicData</td><td>SAT</td><td>State by State SAT data</td><td>50</td><td>8</td></tr><tr><td>openintro</td><td>exam_grades</td><td>Exam and course grades for statistics students</td><td>233</td><td>6</td></tr></tbody></table>


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