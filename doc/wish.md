# I wish

- [ ] 
  - howto
    - in powershell
      ```powershell
      Find-MyTree -Subdirectory request -Tag church
      ```
    - in markdown file
      ```
      # request
      - where: CBC Bible Study Men's
      - tag: church, CBC, men
      - log
      - what
        - AJ
          - a job
          - future
        - Joey
          - repentance
        - Tom
          - family member
            - going through IVF
              - for wisdom
        - Ivan
          - fmily member
            - hates her parents
              - experienced child abuse
              - doesn't want to forgive them
        - David
          - sleep for family
      ```
  - expected
    ```
    - AJ
      - where
        - CBC Bible Study Men's
      - tag
        - church, CBC, men
      - log
      - what
        - a job
        - future
    - Joey
      - where
        - CBC Bible Study Men's
      - tag
        - church, CBC, men
      - log
      - what
        - repentance
    - Tom
      - where
        - CBC Bible Study Men's
      - tag
        - church, CBC, men
      - log
      - what
        - family member
          - going through IVF
            - for wisdom
    - Ivan
      - where
        - CBC Bible Study Men's
      - tag
        - church, CBC, men
      - log
      - what
        - fmily member
          - hates her parents
            - experienced child abuse
            - doesn't want to forgive them
    - David
      - where
        - CBC Bible Study Men's
      - tag
        - church, CBC, men
      - log
      - what
        - sleep for family
    ```
  - expected
    ```
    - where
      - CBC Bible Study Men's
    - tag
      - church, CBC, men
    - what
      - AJ
        - a job
        - future
      - Joey
        - repentance
      - Tom
        - family member
          - going through IVF
            - for wisdom
      - Ivan
        - fmily member
          - hates her parents
            - experienced child abuse
            - doesn't want to forgive them
      - David
        - sleep for family
    ```

- [ ] action trees had a low-emphasis branch (e.g. ``log``) that could be muted for ``Find-MyTree``

- [ ] ``Get-MySchedule`` had ``-Week`` and ``-Month``

- [ ] recurring schedule items had ``startDate`` (and possibly ``endDate``)

- [ ] ``MySchedule`` functions had ``-WhatIf`` flag

- [ ] ``Get-MarkdownTable`` could extricate style information, such as *italic* _text_ or **bold** __text__

- [ ] the node delimiter ``:`` would have an escape sequence

- [ ] ``Get-MarkdownTable``
  
  - actual
    
    ```powershell
    > (cat example.md | Get-MarkdownTable).list.list_subitem
    
    when       what
    ----       ----
    2023_01_05 sus
    2023_01_06 ihr
    2023_01_07 oth
    ```
  
  - expected
    
    ```powershell
    > cat example.md | Get-MarkdownTable
    
    when       what
    ----       ----
    2023_01_05 sus
    2023_01_06 ihr
    2023_01_07 oth
    ```

- [ ] I could identify expired action items
  
  - and have the option
    - to remove them
    - or to move them to an archive or ignored folder

- [ ] I could see expired action items from earlier today

- [ ] I could see high-priority deadlines within a week or month's notice but low-priority deadlines within a day's notice

- [ ] 2022_11_09_175458
  
  - I could write action items in list form under a single ``sched`` heading, using the ``what`` field as the title
    
    - example
      
      - typical form
        
        ```
        # sched
        - what: read
        - when: mon-1800
        - every: week
        - type: routine
        
        # sched
        - what: write
        - when: tue-1800
        - every: week
        - type: routine
        ```
      
      - new form
        
        ```
        # sched
        - read
          - when: mon-1800
          - every: week
          - type: routine
        - write
          - when: tue-1800
          - every: week
          - type: routine
        ```

## resolved

- [x] ``MySchedule`` functions had parameter inference
  - [x] ``Get-MySchedule``
  - [x] ``Find-MyTree``

- [x] an action item could tell me in schedule view whether or not it has an unfinished todo-list

- [x] I could identify and interact with the checkboxes that appear in markdown action items

- [x] I could schedule an action item for the same time every monday, friday, and saturday
  
  - solution
    
    - refactor: ``every' = every union 2^(Mon + Tue + Wed + ... + Sun)``
      
      ```
      example
          every: Mon, Tue, Wed, Fri
      thus
          every = (Mon: (0|1), Tue: (0|1), ... Sun: (0|1))
          every = (2, 2, 2, 2, 2, 2, 2)
          every = 2^7
          every = 2^(Mon + Tue + Wed + ... + Sun)
      ```
    
    - example
      
      ```
      # sched
      - what: college development course
      - when: 1000
      - every: Mon, Wed, Fri
      - type: routine
      ```
      
      - above is equivalent to
      
      ```
      # sched
      - what: college development course
      - when: mon-1000
      - every: week
      - type: routine
      
      # sched
      - what: college development course
      - when: wed-1000
      - every: week
      - type: routine
      
      # sched
      - what: college development course
      - when: fri-1000
      - every: week
      - type: routine
      ```

- [x] I wish I could access an action item's file by selecting from a numbered list
  
  - karlr: Why not just use 'sls' or 'grep'?
  - solution: C:\shortcut\bin\schedsearch.bat

- [x] I could parse text rendered by the ``Write-*`` cmdlets but still see different-colored text

- [x] I could see today's work schedule

---

[Back to Readme](../readme.md)
