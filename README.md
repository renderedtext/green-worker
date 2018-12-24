# GreenWorker

Worker process behavior:
- Elixir swarm used to sync distributed process registry
- When supervisor is started it supervises the whole table:
  - it creates 2 processes: WorkerSupervisor and WorkerSupervisor.Init
    - WorkerSupervisor is created first
    - WorkerSupervisor.Init second
    - `rest_for_one` strategy 
- For each process family state is kept in a single DB table
  - One row is represented (written to) by single process
  - Row has to be created before process is created
