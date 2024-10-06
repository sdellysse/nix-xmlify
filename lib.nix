{ lib }:
with builtins;
with lib;
{
  assertInline =
    fn: value:
    assert (fn value);
    value;

  attrsToList =
    attrs:
    pipe attrs [
      (getAttrNames)
      (map (name: {
        name = name;
        value = attrs.${name};
      }))
    ];

  atIndex = list: index: if ((length list) >= (index + 1)) then (elemAt list index) else (null);

  atName = set: name: if (set ? name) then (set.${name}) else (null);

  parseTag =
    input:
    pipe input [
      (assertInline (input: (isList input) || (isAttrs input)))
      (input: {
        name = pipe input [
          (input: (if (isAttrs input) then (atName input "name") else (atIndex input 0)))
          (assertInline (name: (name != null) && (isString name) && ((stringLength name) > 0)))
        ];

        attributes = pipe input [
          (input: if (isAttrs input) then (atName input "attributes") else (atIndex input 1))
          (attributes: if (attributes != null) then (attributes) else ({ }))
          (attrsToList)
          (filter ({ name, value }: value != null))
          (map (assertInline ({ name, ... }: (isString name) && ((stringLength name) > 0))))
          (map (
            assertInline (
              { value, ... }: (isBool value) || (isFloat value) || (isInt value) || (isString value)
            )
          ))
          (listToAttrs)
        ];

        children = pipe input [
          (input: if (isAttrs input) then (atName input "children" null) else (atIndex input 2 null))
          (children: if (children != null) then (children) else ([ ]))
          (map parseTag)
        ];
      })
    ];

  tagToXml =
    tag:
    pipe tag [
      (tag: {
        name = pipe tag.name [
          (it: it)
        ];

        attributes = pipe tag.attributes [
          (attrsToList)
          (map (
            { name, value }:
            if (isBool value) then
              (if (value) then ''${name}="${name}"'' else '''')
            else
              ''${name}="${toString value}"''
          ))
          (filter (it: ((stringLength it) > 0)))
          (concatStringSep " ")
        ];

        children = pipe tag.children [
          (map tagToXml)
          (concatStringSep "\n")
        ];
      })

      (
        strings:
        if ((stringLength strings.children) == 0) then
          ''<${strings.name} ${strings.attributes} />''
        else
          ''
            <${strings.name} ${strings.attributes}>
              ${strings.children}
            </${strings.name}>
          ''
      )

      (xmlString: ''
        <?xml version='1.0' encoding='UTF-8'?>
        ${xmlString}
      '')
    ];

  xmlify =
    input:
    pipe input [
      (parseTag)
      (tagToXml)
    ];
}
