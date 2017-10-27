# poppler-lambda
Build poppler for AWS lambda

### Build
1. Create an EC2 instance using the public Amazon Linux AMI (AMI name: `amzn-ami-hvm-2017.03.1.20170812-x86_64-gp2`)
2. Download and run the `build.sh` script.
3. The script will generate a `poppler.tgz` package which contains poppler util executables and all the required shared objects. The content of `poppler.tgz` will then have the following structure:

```
poppler
├── bin (Contain poppler util executables)
├── lib (Contain poppler required shared objects)
└── share (Contain poppler encoding data for CJK)
```

### Create deployment package
To create a Lambda function deployment package, you can extract the `bin/`, `lib/` and `share/` folders from `poppler.tgz` and put them under `LAMBDA_TASK_ROOT`. Optionally, you can add `$LAMBDA_TASK_ROOT/bin` to the `PATH` environment variable.

The following is an example that uses poppler util. If you put the folders under `LAMBDA_TASK_ROOT`, it should work in AWS Lambda environment.

```python
import os.path
import subprocess

def handle(event, context):
    poppler_bin = os.path.join(os.environ['LAMBDA_TASK_ROOT'], 'bin')
    os.environ['PATH'] = os.environ['PATH'] + ':' + poppler_bin
    cmd = ['pdfinfo', '-f', '1', '-l', '1', '-box', 'test.pdf']
    subprocess.check_output(cmd)
```

### Reference
- [Poppler](http://www.linuxfromscratch.org/blfs/view/cvs/general/poppler.html)
- [Lambda Execution Environment](http://docs.aws.amazon.com/lambda/latest/dg/current-supported-versions.html)
