

## h3-cli: Downloading pentest resports


Below is a simple shell script that fetches the pentest-reports archive for a given `op_id`.
The pentest-reports archive contains all CSV and PDF reports for the pentest.

The script first fetches a presigned URL for archive file, then downloads it.

```shell
url=`h3 pentest_reports_zip_url "your-op-id-here" | jq -r .data.pentest_reports_zip_url`
curl -o pentest_reports.zip "$url"
```

> The presigned URL expires after a short time so it must be used promptly.
