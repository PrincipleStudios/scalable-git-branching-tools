# Local Action 'recurse'

This action is intended to run another script recursively. The primary action
looks like this:

```json
{
    "type": "recurse",
    "parameters": {
        "inputParameters": [],
        "path": "path-to-recursion-script.json"
    }
}
```

- `inputParameters` is an array of seed inputs into the recursion script; the
  initial stack. This must be an array of objects. If a `depth` property is not
  set on any of the input objects, `depth` will be added to indicate the recursive
  depth of the algorithm, starting with 0 for the initial input.
- `path` is the path to the recursion script, based on the root of this
  repository.

## Recursive Script definition

The contents of the recursion script should be something like the following:

```json
{
    "recursion": {
        "mode": "depth-first", // otherwise behaves as breadth-first
        "paramScript": "pwsh-script",
        "map": "pwsh-script",
        "reduceToOutput": "pwsh-script",
        "actCondition": "pwsh-script" // optional
    },
    "prepare": [
        // set of local-actions
    ],
    "act": [
        // set of local-actions
    ]
}
```

### `recursion.mode`

If `depth-first`, recursion will be done via a depth-first strategy. Otherwise,
recursion will be breadth-first.

### `recursion.paramScript`

A powershell script that:
- runs after the `prepare` actions for each input of the recursive algorithm
- receives the following variables:
    - `$params` contains the current input object of the recursive algorithm.
    - `$actions` is the result of the `prepare` actions
- should return an array of new inputs for the recursive algorithm

### `recursion.map`

A powershell script that:
- runs after the `act` actions for each input of the recursive algorithm
- receives the following variables:
    - `$params` contains the current input object of the recursive algorithm.
    - `$actions` is the result of the `prepare` actions
- should return a value to be reduced in the `recursion.reduceToOutput` script

### `recursion.reduceToOutput`

A powershell script that:
- runs after all `recursion.map` scripts have run
- receives the following variables:
    - `$mapped` is an array containing the results of each previous
      `recursion.map` script
- returns the value to be bound to the output of the `recurse` action that
  invoked the script

### `recursion.actCondition`

An optional powershell script that:
- runs after the `prepare` actions for each input of the recursive algorithm
- receives the following variables:
    - `$params` contains the current input object of the recursive algorithm.
    - `$actions` is the result of the `prepare` actions
- returns a falsy value if the `act` actions should not be run for this
  recursive input

### `prepare`

A set of "local" actions that:
- run once for each set of inputs, before any `act` actions are run
- in the order as determined by `recursion.mode`

### `act`

A set of "local" actions that:
- run once for each set of inputs, after all `prepare` actions are run
- if the `recursion.actCondition` is either not present or evaluates to a truthy
  value
- in the order as determined by `recursion.mode`
