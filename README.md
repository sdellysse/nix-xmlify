### `nix-xmlify`

## Summary
Pure nixlang code for converting a nix data structure like 

```nix
[div { id = "picture"; } [ 
    ["img" { src = "dogs.png"; }] 
]]
```

or

```nix
{
    name = "div";
    attributes = {
        id = "picture";
    };
    children = [
        ["img" { src = "dogs.png"; }]
    ];
}
```

into the following xml:

```xml
<?xml version='1.0' encoding='UTF-8'?>
<div id="picture">
  <img src="dogs.png" />
</div>
```

## Usage

In flake:

```nix
{
    inputs = {
        nix-xmlify = {
            url = "github:sdellysse/nix-xmlify";
        };
    };

    outputs = {nixpkgs, nix-xmlify, ...}: let
      system = "x86_64-linux";
      xmlify = nix-xmlify.xmlify.${system};
    in {
        # ...

        services.log4j2.config = pkgs.writeTextFile "log4j2.xml" (xmlify 
            ["Configuration" { status = "warn"; } [
                ["Appenders" { name = "console"; target = "SYSTEM_OUT"; } [
                    ["PatternLayout" { pattern = "%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m%n"; }]
                ]]
                ["Loggers" {} [
                    ["Root" { level = "info"; additivity = "false" } [
                        ["AppenderRef" { ref = "console"; }]
                    ]]
                ]]
            ]]
        );
        # generates a file "log4j2.xml" with the following contents:
        #
        # <?xml version="1.0" encoding="UTF-8"?>
        # <Configuration status="warn">
        #     <Appenders>
        #         <Console name="console" target="SYSTEM_OUT">
        #             <PatternLayout
        #                 pattern="%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m%n" />
        #         </Console>
        #     </Appenders>
        #     <Loggers>
        #         <Root level="info" additivity="false">
        #             <AppenderRef ref="console" />
        #         </Root>
        #     </Loggers>
        # </Configuration>

        # ...
    };
}
```

### TODO

- Unit tests
- proper string escaping