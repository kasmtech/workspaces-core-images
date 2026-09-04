#!/usr/bin/env python3

from jinja2 import Template
import yaml
import os

# Determine if this is a feature branch and what variables to pass
fileLimits = True
scheduled = 'NO'
scheduleName = 'NO'
if os.getenv('SANITIZED_BRANCH').startswith('release') or os.getenv('SANITIZED_BRANCH') == 'develop':
  fileLimits = False
if os.getenv('CI_PIPELINE_SOURCE') == 'schedule':
  fileLimits = False
  scheduled = 'YES'
if 'SCHEDULE_NAME' in os.environ:
  scheduleName = os.getenv('SCHEDULE_NAME')

# Read yaml file with variables
with open("template-vars.yaml", 'r') as stream:
  templateVars = yaml.safe_load(stream)
  templateVars['KASM_RELEASE'] = os.getenv('KASM_RELEASE')
  templateVars['TEST_INSTALLER'] = os.getenv('TEST_INSTALLER')
  templateVars['SANITIZED_BRANCH'] = os.getenv('SANITIZED_BRANCH')
  templateVars['FILE_LIMITS'] = fileLimits
  templateVars['SCHEDULED'] = scheduled
  templateVars['SCHEDULE_NAME'] = scheduleName

  # Defaults e2e_playwright to true for every image now that the ubuntu/noble
  # and fedora/43 canaries are green against both target architectures
  # (including aarch64 session recording, which needed the xhost fix in
  # src/ubuntu/install/recorder/install_recorder.sh) -- both legs run on the
  # oci-amd-scheduled runner, driving an x86_64 or aarch64 EC2 test instance
  # respectively; the runner itself is never arm64. An entry can still opt
  # out with `e2e_playwright: false` in template-vars.yaml if a specific
  # image needs more time on Selenium's kasm-tester -- that's the escape
  # hatch now, not a growing allow-list.
  for imageList in (templateVars.get('multiImages', []), templateVars.get('singleImages', [])):
    for image in imageList:
      image.setdefault('e2e_playwright', True)

# Read template file
with open("gitlab-ci.template", 'r') as stream:
  template = stream.read()

# Template the variables in
jinjaTemplate = Template(template)
gitlabCi = jinjaTemplate.render(templateVars)

# Write out the gitlab file
with open('../gitlab-ci.yml', 'w') as out:
    out.write(gitlabCi + '\n')
