# BOOM paper

The first paper about BOOM development.

To clone the project, including all datasets and artifacts, run:

```sh
calkit clone --recursive petebachant/boom-paper
```

This will require that you have installed
[Calkit](https://github.com/calkit/calkit) and set up both
[cloud](https://docs.calkit.org/cloud-integration/)
and
[Overleaf integration](https://docs.calkit.org/overleaf/).

To sync the paper with Overleaf, execute:

```sh
calkit overleaf sync
```

To run the benchmarks and build the paper, execute:

```sh
calkit run
```

Note that if none of the benchmarking input data or scripts have changed,
the expensive steps will not be rerun.
