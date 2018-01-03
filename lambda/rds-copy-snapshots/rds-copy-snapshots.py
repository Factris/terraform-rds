from __future__ import print_function
from dateutil import parser, relativedelta
from boto3 import client
import os

# The number of months to keep ONE snapshot per month
RETENTION_MONTHS = int(os.environ.get('RETENTION_MONTHS'))
RETENTION_WEEKS = int(os.environ.get('RETENTION_WEEKS'))
RETENTION_DAYS = int(os.environ.get('RETENTION_DAYS'))

# AWS region in which the db instances exist
REGION = os.environ.get('REGION')

CLUSTERS = os.environ.get('CLUSTERS')


def copy_snapshots(rds, snaps, cluster_arn, prefix):
    newest = snaps[-1]
    response = rds.list_tags_for_resource(ResourceName=cluster_arn)
    rdstags = response['TagList']
    rdstags.append({'Key': 'backup_type', 'Value': prefix})
    print("Copying Snapshot {} to {}".format(
        newest['DBClusterSnapshotIdentifier'],
        prefix + newest['DBClusterSnapshotIdentifier'][4:])
    )
    rds.copy_db_cluster_snapshot(
        SourceDBClusterSnapshotIdentifier=newest['DBClusterSnapshotIdentifier'],
        TargetDBClusterSnapshotIdentifier=prefix + newest['DBClusterSnapshotIdentifier'][4:],
        Tags=rdstags)
    print("Snapshot {} copied to {}".format(
          newest['DBClusterSnapshotIdentifier'],
        prefix + newest['DBClusterSnapshotIdentifier'][4:])
          )


def purge_snapshots(rds, id, snaps, counts, prefix, delete_before_date):
    newest = snaps[-1]
    prev_start_date = None
    delete_count = 0
    keep_count = 0

    print("---- RESULTS FOR {} ({} snapshots) ----".format(id, len(snaps)))

    for snap in snaps:
        snap_date = snap['SnapshotCreateTime']
        snap_age = NOW - snap_date

        start_date_str = snap_date.strftime("%Y-%m-%d")
        if (start_date_str != prev_start_date and
                snap_date > delete_before_date):
            # Keep it
            prev_start_date = start_date_str
            print("Keeping {}: {}, {} days old - {} of {}".format(
                  snap['DBClusterSnapshotIdentifier'], snap_date, snap_age.days,
                  prefix, start_date_str)
                  )
            keep_count += 1
        else:
            # Never delete the newest snapshot
            if snap['DBClusterSnapshotIdentifier'] == newest['DBClusterSnapshotIdentifier']:
                print(("Keeping {}: {}, {} hours old - will never"
                      " delete newest snapshot").format(
                      snap['DBClusterSnapshotIdentifier'], snap_date,
                      snap_age.seconds/3600)
                      )
                keep_count += 1
            else:
                # Delete it
                print("- Deleting{} {}: {}, {} days old".format(
                      NOT_REALLY_STR, snap['DBClusterSnapshotIdentifier'],
                      snap_date, snap_age.days)
                      )
                if NOOP is False:
                    rds.delete_db_cluster_snapshot(
                        DBClusterSnapshotIdentifier=snap['DBClusterSnapshotIdentifier']
                        )
                delete_count += 1
    counts[id] = [delete_count, keep_count]


def get_snaps_filtered(rds, cluster, snap_type, prefix):
    str_status_type = "avail"
    snapshots = rds.describe_db_cluster_snapshots(
                SnapshotType=snap_type,
                DBClusterIdentifier=cluster)['DBClusterSnapshots']
    snapshots = filter(lambda x: x['Status'].startswith(str_status_type), snapshots)  # filter snaps based on status=available - returning only snaps that not creating or deleting
    snapshots = filter(lambda x: x['DBClusterSnapshotIdentifier'].startswith(prefix), snapshots)  # filter the snapshots based on the the first letters of the DBSnapshotIdentifier
    return sorted(snapshots, key=lambda x: x['SnapshotCreateTime'])


def get_snaps(rds, cluster, snap_type):
    snapshots = rds.describe_db_cluster_snapshots(
                SnapshotType=snap_type,
                DBClusterIdentifier=cluster)['DBClusterSnapshots']
    snapshots = filter(lambda x: x['Status'].startswith('avail'), snapshots)  # filter snaps based on status=available - returning only snaps that not creating or deleting
    return sorted(snapshots, key=lambda x: x['SnapshotCreateTime'])


def print_summary(counts):
    print("\nSUMMARY:\n")
    for id, (deleted, kept) in counts.iteritems():
        print("{}:".format(id))
        print("  deleted: {}{}".format(
              deleted, NOT_REALLY_STR if deleted > 0 else "")
              )
        print("  kept:    {}".format(kept))
        print("-------------------------------------------\n")


def lambda_handler(event, context):
    print("Starting backup process")
    global NOW
    global NOOP
    global NOT_REALLY_STR

    NOW = parser.parse(event['time'])

    if NOW.day == 1:
        prefix = 'mo-'
        delete_before_date = (NOW - relativedelta.relativedelta(months=RETENTION_MONTHS))
        print('Monthly backup in progress')
    elif NOW.weekday() == 0:
        prefix = 'we-'
        delete_before_date = (NOW - relativedelta.relativedelta(weeks=RETENTION_WEEKS))
        print('Weekly backup in progress')
    else:
        prefix = 'da-'
        delete_before_date = (NOW - relativedelta.relativedelta(days=RETENTION_DAYS))
        print('Daily backup in progress')

    NOOP = event['noop'] if 'noop' in event else False
    NOT_REALLY_STR = " (not really)" if NOOP is not False else ""
    process_backups(prefix, delete_before_date)


def process_backups(prefix, delete_before_date):
    rds = client("rds", region_name=REGION)

    clusters = CLUSTERS.split(":")

    if clusters:
        for cluster in clusters:
            instance_counts = {}
            snapshots_auto = get_snaps(rds, cluster, 'automated')
            if snapshots_auto:
                print("Processing Snapshots for instance: {} ".format(cluster))
                response = rds.describe_db_clusters(DBClusterIdentifier=cluster)
                dbins = response['DBClusters']
                dbin = dbins[0]
                dbarn = dbin['DBClusterArn']
                print("The instance arn is:  {} ".format(dbarn))
                copy_snapshots(rds, snapshots_auto, dbarn, prefix)
            else:
                print("No auto snapshots found for cluster: {}, stopping".format(
                    cluster)
                )
                # do not delete any backups when there are no new candidates
                # so we return here
                return
            snapshots_manual = get_snaps_filtered(rds, cluster, 'manual', prefix)
            if snapshots_manual:
                print("Script start time is: ", NOW, " \n")
                print("Snapshots will be deleted prior to: ", delete_before_date, " \n")
                purge_snapshots(rds, cluster,
                                snapshots_manual, instance_counts, prefix, delete_before_date)
                print_summary(instance_counts)
            else:
                print("No manual snapshots found for cluster: {}".format(
                    cluster)
                )
    else:
        print("You must populate the CLUSTERS variable.")
