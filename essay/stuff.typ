
// TODO: figure out the right ABNT spacing 
// TODO: figure out line numbering
// TODO: figure out how to put chapter name in page corner
// TODO: figure out how to put numbers in headings

/// General page settings
#let template(doc) = [
  
  #set text(lang: "pt", region: "br")
  #set quote(block: true)

  #show heading.where(
    level: 1
  ): it => [
    #text(25pt)[
    #it.body
    ]

  ]

  #show heading.where(
    level: 2
  ): it => [
    #text(16pt)[
    #it.body
    ]

  ]


  #doc
]
