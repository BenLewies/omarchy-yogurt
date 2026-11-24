# Store submission

This is the listing reference for Yogurt Bar. The official directory requires
a public repository, automated validation and maintainer approval.

## Listing copy

**Name:** Yogurt Bar  
**Repository:** https://github.com/BenLewies/omarchy-yogurt  
**Plugin ID:** `bjl.yogurt`  
**Version:** `1.1.0`  
**Category:** Productivity  
**Suggested keywords:** Yogurt, meeting notes, recording

**Short description**

Your calls, in view. Recording controls, a live session timer and recent meeting
status for Yogurt, right in the Omarchy bar.

**Feature description**

Stay in the conversation. Yogurt Bar puts recording status and controls one
click away: start, pause, resume and finish without hunting for a hidden tray
menu. A compact timer makes active recording easy to spot, while a polished
panel keeps recent conversations and processing status close at hand. Your
recordings remain in Yogurt. The plugin uses native tray controls and reads
only local session metadata—no accounts, API keys or extra cloud services.

**Preview:** `preview.png` at the repository root. Actual app screenshot;
meeting titles can be hidden using the privacy setting.

## Publish when ready

1. Review the repository, README, license and preview. Remove any private data.
2. Change the GitHub repository visibility to public. This is an owner decision;
   it is not done by the included workflow.
3. Validate on an Omarchy desktop:
   ```bash
   omarchy plugin validate .
   python -m unittest discover -s tests -v
   node tests/model.test.cjs
   python tests/check_package.py
   ```
4. Publish the `v1.1.0` release with the existing changelog.
5. Open the submission link from the [official publishing guide](https://plugins.omarchy.org/publish.html)
   and submit the repository URL, listing copy and preview.

The included GitHub workflow runs checks only. It does not publish the plugin,
change visibility or submit anything on the owner's behalf.
