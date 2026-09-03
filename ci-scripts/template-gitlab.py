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

  # e2e_playwright defaults to false for every image (multi and single)
  #   unless an entry explicitly opts in with `e2e_playwright: true` in
  #   template-vars.yaml. Starting false, not true, because unlike
  #   workspaces-images (which calibrated against its own image matrix
  #   before flipping this default), no core image has run the Playwright
  #   calibration suite yet -- opt in image by image as each is verified
  #   green, then flip this default once the matrix is covered.
  for imageList in (templateVars.get('multiImages', []), templateVars.get('singleImages', [])):
    for image in imageList:
      image.setdefault('e2e_playwright', False)

# Read template file
with open("gitlab-ci.template", 'r') as stream:
  template = stream.read()

# Template the variables in
jinjaTemplate = Template(template)
gitlabCi = jinjaTemplate.render(templateVars)

# Write out the gitlab file
with open('../gitlab-ci.yml', 'w') as out:
    out.write(gitlabCi + '\n')
