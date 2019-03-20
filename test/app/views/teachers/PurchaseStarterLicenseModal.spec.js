const PurchaseStarterLicenseModal = require('views/teachers/PurchaseStarterLicensesModal');

describe('PurchaseStarterLicenseModal', () => {
    it('initializes state properly', () => {
        const view = new PurchaseStarterLicenseModal();
        const state = view.state;

        expect(state.get('quantityToBuy')).toEqual(10);

        // TODO validate that initial prepaid amount is correct
        // TODO validate that starter license product data is loaded correctly
    });

    it('properly renders the quantity purchased');
    it('properly renders the starter license length');
    it('initializes stripe properly');
    it('listens to stripe callback properly');
    it('properly posts purchase to backend');
    it('properly enforces maximum quantities at input');
});
