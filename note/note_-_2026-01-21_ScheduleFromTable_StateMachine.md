# note: ``ScheduleFromTable`` State Machine

## properties

```text
startdate
enddate
list
when
type
every
complete

to (karlr 2026-04-18)
duration (karlr 2026-04-18)
```

## state machine

```text
0 start
    B if
        no item or
        item's time frame does not include now

    C if
        item has 'list' property

    B if
        item has no 'when' property

    D if
        item's 'when' property is empty

    E if
        item's 'when' property is not a string

    F if
        item is 'type' 'todo'

    I if
        item is 'type' 'deadline' and
        item has 'every'

    if item is 'every'
        'none'
            today-only
                if not in range
                    discard
                else
                    homogenize row and add to list
                return list
                end

            one-day-event
                homogenize row and add to list
                return list
                end

            pass

        'day'
            if item has no time
                invalid
                discard
                end

            pass

        'week'
            if item has no day-code or no time
                invalid
                discard
                end

            replace date with StartDate
            advance date to next day-code date
            pass

        day-code list
            each item in this list is equivalent to an every-week item with a day-code-when

            for each daycode
                clone the item and assign it a day-code-time-when
                add clone to list

            return list
            end

I prioritize deadline over recurrence
    overwrite 'every' with 'none'

H fully-formed action item
    add 'complete' property to item
    parse and relay date-time

G expired
    B

F action item
    G if
        item has 'complete' property and
        item's 'complete' property is True

    H if
        item's 'when' property has checkbox next to date-time

E recurse over nested time table
    A

D pending reappointment
C recurse over list
    A

B discard
    A

A end
```

