# BOOM paper

[![DOI](https://data.caltech.edu/badge/DOI/10.22002/640bx-nbn45.svg)](https://handle.stage.datacite.org/10.22002/640bx-nbn45)

The first paper about BOOM/Babamul development,
for which the preprint is available on
[arXiv](https://arxiv.org/abs/2511.00164).

To clone the project, including all datasets and artifacts, run:

```sh
calkit clone boom-astro/boom-paper
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

To run the benchmarks, analyze the logs, generate the figures,
and build the paper, execute:

```sh
calkit run
```

Note that if none of the benchmarking input data or scripts have changed,
the expensive steps will not be rerun.
