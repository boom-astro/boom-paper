# BOOM paper

The first paper about BOOM development.

To clone the project, including all datasets and artifacts, run:

```sh
calkit clone --recursive petebachant/boom-paper
```

To run the benchmarks and build the paper, execute:

```sh
calkit run
```

The pipeline (defined in `calkit.yaml`) will sync the paper with Overleaf
before compiling.
This means the paper can be edited either here or on Overleaf,
and figures generated here can be pushed up there so manual uploads
are not necessary.

Note that if none of the benchmarking input data or scripts have changed,
the expensive steps will not be rerun.
