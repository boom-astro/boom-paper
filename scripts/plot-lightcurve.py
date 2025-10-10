import matplotlib.pyplot as plt
import pandas as pd

# plot the photometry
# for ZTF, we use circles for regular data, crosses for forced photometry
# for DECAM, we use squares for all
markers = {
    "ZTF": {"fp": "x", "regular": "o"},
    "DECam": {"fp": "s", "regular": "s"},
}
marker_sizes = {
    "ZTF": 6,
    "DECam": 9,
}
color_map = {
    "g": "green",
    "r": "red",
    "i": "orange",
    "z": "purple",
    "y": "brown",
}


def group_photometry(photometry_path):
    # load the photometry from a parquet file
    photometry = pd.read_parquet(photometry_path).to_dict(orient="records")
    print(f"Loaded {len(photometry)} photometry points from {photometry_path}")

    # drop all non detections (mag is None)
    photometry = [
        p
        for p in photometry
        if p["mag"] is not None and p["magerr"] is not None
    ]
    print(
        f"Reduced to {len(photometry)} photometry points after removing non-detections"
    )

    # for that group by filter, origin, and instrument
    grouped = {}
    for p in photometry:
        key = (p["filter"], p["origin"], p["instrument_name"])
        if key not in grouped:
            grouped[key] = []
        grouped[key].append(p)

    # get the min mjd of all points
    min_mjd = min(p["mjd"] for p in photometry)

    return grouped, min_mjd


def plot_photometry(
    grouped, min_mjd, ids, at_name=None, export=None, out_dir="."
):
    _, ax = plt.subplots(figsize=(10, 6))
    for (filter, origin, instrument), points in grouped.items():
        color = color_map.get(filter, "black")
        marker_size = marker_sizes.get(instrument, 50)
        mjds = [p["mjd"] for p in points]
        mjds = [t - min_mjd for t in mjds]
        mags = [p["mag"] for p in points]
        magerrs = [p["magerr"] for p in points]
        if origin == "fp":
            marker = markers.get(instrument, {}).get("fp", "s")
            label = f"{instrument} {filter} (fp)"
        else:
            marker = markers.get(instrument, {}).get("regular", "o")
            label = f"{instrument} {filter}"

        if instrument == "DECam":
            # for decam, plot the first point with the regular marker, then the rest with lower opacity and a smaller marker size
            ax.errorbar(
                mjds[0:1],
                mags[0:1],
                yerr=magerrs[0:1],
                fmt=marker,
                label=label,
                linestyle="None",
                alpha=0.75,
                color=color,
                markersize=marker_size,
            )
            if len(mjds) > 1:
                ax.errorbar(
                    mjds[1:],
                    mags[1:],
                    yerr=magerrs[1:],
                    fmt=marker,
                    linestyle="None",
                    alpha=0.4,
                    color=color,
                    markersize=(marker_size),
                )
        else:
            ax.errorbar(
                mjds,
                mags,
                yerr=magerrs,
                fmt=marker,
                label=label,
                linestyle="None",
                alpha=0.75,
                color=color,
                markersize=marker_size,
            )

    ax.invert_yaxis()
    ax.set_xlabel("Time since first detection (days)")
    ax.set_ylabel("AB Magnitude")
    if at_name is not None:
        ax.set_title(f"Photometry of {at_name} ({', '.join(ids)})")
    else:
        ax.set_title(f"Photometry of {', '.join(ids)}")
    ax.legend()
    ax.grid()
    ax.legend(loc="upper left", fontsize="small")
    if export is not None:
        plt.savefig(f"{out_dir}/{at_name}.{export}", bbox_inches="tight")
    plt.show()


ids = ("ZTF25aaqsuda", "C202505201402422m202612")
at_name = "SN2025kwy"

grouped_photometry, min_mjd = group_photometry("./data/SN2025kwy.parquet")

plot_photometry(
    grouped_photometry,
    min_mjd,
    ids,
    at_name,
    export="pdf",
    out_dir="./paper/figures",
)
