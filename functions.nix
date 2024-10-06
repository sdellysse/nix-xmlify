{ nixpkgsLib }:
with builtins;
with nixpkgsLib;
let
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

  Tag = rec {
    isTagName = input: (isString input) && ((stringLength input) > 0);
    isTagAttributes = input: true;
    isTagChildren = input: true;

    isTag =
      input:
      if (false) then
        throw "will never get here"

      else if (isAttrs input) then
        true
        && (if (!(input ? "name")) then (false) else (Tag.isTagName input.name))
        && (
          if (!(input ? "attributes")) then
            (true)
          else
            ((input.attributes == null) || (isAttrs input.attributes && (Tag.isTagAttributes input.attributes)))
        )
        && (
          if (!(input ? "children")) then
            (true)
          else
            ((input.attributes == null) || (isList input.children && (Tag.isTagChildren input.children)))
        )

      else if (isList input) then
        true
        && (
          if (false) then
            throw "will never get here"

          else if ((length input == 3)) then
            true
            && (Tag.isTagName (elemAt input 0))
            && (((elemAt input 1) == null) || (Tag.isTagAttributes (elemAt input 1)))
            && (((elemAt input 2) == null) || (Tag.isTagChildren (elemAt input 2)))

          else if ((length input == 2)) then
            true
            && (Tag.isTagName (elemAt input 0))
            && (((elemAt input 1) == null) || (Tag.isTagAttributes (elemAt input 1)))

          else if ((length input == 1)) then
            true && (Tag.isTagName (elemAt input 0))

          else
            false
        )

      else
        false;

    guard =
      input:
      assert (Tag.isTag input);
      input;

    nameOf =
      tag:
      pipe tag [
        (Tag.isTag)
        (tag: if (isAttrs tag) then (tag.name) else (elemAt tag 0))
      ];

    attributesOf =
      tag:
      pipe tag [
        (Tag.isTag)
        (
          tag:
          if (isAttrs tag) then
            (if (tag ? "attributes") then (tag.attributes) else (null))
          else
            (if ((length tag) > 1) then (elemAt tag 1) else (null))
        )
        (attributes: if (attributes != null) then (attributes) else ({ }))
      ];

    childrenOf =
      tag:
      pipe tag [
        (Tag.isTag)
        (
          tag:
          if (isAttrs tag) then
            (if (tag ? "children") then (tag.children) else (null))
          else
            (if ((length tag) > 2) then (elemAt tag 2) else (null))
        )
        (children: if (children != null) then (children) else ([ ]))
      ];
  };
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
in
{
  inherit
    assertInline
    attrsToList
    atIndex
    atName
    parseTag
    tagToXml
    xmlify
    ;
}
