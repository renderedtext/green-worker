# GreenWorker

Not production ready!

Elixir library for managing family of similar processes.
Process states are synchronized with database.
Processes are modeled with sequence of operations that need to be performed
in each state in order to transition to subsequent state.

See [documentation](https://hexdocs.pm/green_worker/) for more information.

## Installation
Add `GreenWorker` to the list of dependencies in mix.exs:
```
{:green_worker, "~> 0.1"}
```

## License
Copyright 2018 RenderedText

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
