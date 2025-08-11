# SponsorAll

SponsorAll is a flexible sponsorship management solution built on Salesforce, designed to help organizations define sponsorable items, sponsorship needs, and manage pledges and transactions seamlessly. This solution supports recurring sponsorships, installment plans, tagging, segmentation, and customizable attributes for a wide range of use cases.

# NOTICE!

Sponsorall is an attempt to use several different AI models with the goal being to identity what a real production ready development pipeline would look like. Currently this project is NON FUNCTIONAL and under HEAVY Continual Refactoring.  I will attempt to Annotate AI specific Commits with which AI suggested the changes.

## Current Features

- Define sponsorable entities and their specific sponsorship needs  
- Manage sponsorship opportunities linked to sponsors (Contacts)  
- Track sponsorship transactions and payment line items  
- Support for recurring and installment-based sponsorships  
- Tagging and segmentation of sponsorable items and sponsorship needs  
- Custom attribute configuration for client-specific needs  

## Future Development

- **Experience Cloud Shopping Cart:** Allow users to select multiple sponsorship opportunities and pledge support through a streamlined “shopping cart” experience.  
- **User Engagement & Updates:** Provide sponsors with personalized updates on the impact of their sponsorships and upcoming opportunities.  
- **Payment Provider Integrations:** Connect with external payment gateways to securely process transactions.  
- **Advanced Reporting & Analytics:** Enable detailed tracking and reporting dashboards for sponsors and administrators.  

## Getting Started

Check the `/docs` folder for detailed ERD documentation and object/field definitions to help you set up the Salesforce environment.

---

## Development Resources

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)

## Useful commands.
To Make Scratch org from the Org Shape 
sf org create scratch --edition developer --alias sponsorall

To Fetch Changes
sf project retrieve start --target-org sponsorall