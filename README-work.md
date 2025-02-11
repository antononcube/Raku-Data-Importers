# Data::Importers

[![Actions Status](https://github.com/antononcube/Raku-Data-Importers/actions/workflows/linux.yml/badge.svg)](https://github.com/antononcube/Raku-Data-Importers/actions)
[![Actions Status](https://github.com/antononcube/Raku-Data-Importers/actions/workflows/macos.yml/badge.svg)](https://github.com/antononcube/Raku-Data-Importers/actions)

[![](https://raku.land/zef:antononcube/Data::Importers/badges/version)](https://raku.land/zef:antononcube/Data::Importers)
[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)

## In brief

This repository is for a Raku package for the ingestion of different types of data
from both URLs and files. Automatically deduces the data type from extensions.

**Remark:** The built-in sub `slurp` is overloaded by definitions of this package.
The corresponding function `data-import` can be also used.

The format of the data of the URLs or files can be specified with the named argument "format".
If `format => Whatever` then the format of the data is implied by the extension of the given URL or file name.

(Currently) the recognized formats are: CSV, HTML, JSON, Image (png, jpeg, jpg), PDF, Plaintext, Text, XML.

The functions `slurp` and `data-import` can work with:

- CSV files if ["Text::CSV"](https://raku.land/zef:Tux/Text::CSV), [HMBp1], is installed

- PDF files if ["PDF::Extract"](https://raku.land/zef:Tux/PDF::Extract), [SRp1], is installed

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

Instead of `slurp` the function `data-import` can be used (no need to use "format"):

```perl6
data-import($*CWD ~ '/resources/simple.json')
```

### CSV file

```perl6
slurp($*CWD ~ '/resources/simple.csv', format => 'csv', headers => 'auto')
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

Here is the deduced type:

```perl6
use Data::TypeSystem;

deduce-type($res);
```

Using `slurp` instead of `data-import`:

```perl6
slurp($url)
```

### Image URL

Import an [image](https://raw.githubusercontent.com/antononcube/Raku-WWW-OpenAI/main/resources/ThreeHunters.jpg):

```perl6
my $imgURL = 'https://raw.githubusercontent.com/antononcube/Raku-WWW-OpenAI/main/resources/ThreeHunters.jpg';

data-import($imgURL, format => 'md-image').substr(^100)
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

### PDF URL

Here is an example of importing a PDF file into plain text:

```perl6
my $txt = slurp('https://pdfobject.com/pdf/sample.pdf', format=>'text');

say text-stats($txt);
```

**Remark:** The function `text-stats` is provided by this package, "Data::Importers". 

Here is a sample of the imported text:

```perl6
$txt.lines[^6].join("\n")
```


-----

## TODO

- [X] DONE Development
  - [X] DONE PDF ingestion
    - [X] DONE Files 
    - [X] DONE URLs 
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