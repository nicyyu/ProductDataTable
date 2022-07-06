import { LightningElement, api, wire, track } from 'lwc';

import { NavigationMixin } from 'lightning/navigation';

import getRecords from '@salesforce/apex/ProductsListController.getRecords';

import getAccountRecord from '@salesforce/apex/ProductsListController.getAccountRecord';

const columns = [
  { label: 'Product Name', fieldName: 'linkName', type: 'url',
      typeAttributes: {
          label: { fieldName: 'Name' },
          target: '_blank'
      } 
  },
  { label: 'Id', fieldName: 'Id', type: 'text'}
];

const quoteItemColumns = [
  { label: 'Product Name', fieldName: 'linkName', type: 'url',
      typeAttributes: {
          label: { fieldName: 'Name' },
          target: '_blank'
      } 
  },
  { label: 'Id', fieldName: 'Id', type: 'text'}
];
export default class ProductDataTable extends NavigationMixin(LightningElement) {
  //Quote Id, Account Price Book, Account Currency
  @api recordId;
  accountPB;
  accountCurrency;
  columns = columns;
  data = [];
  error;
  totalNumberOfRows = 50; // stop the infinite load after this threshold count
  // offSetCount to send to apex to get the subsequent result. 0 in offSetCount signifies for the initial load of records on component load.
  offSetCount = 0;
  loadMoreStatus;
  targetDatatable; // capture the loadmore event to fetch data and stop infinite loading

  boolVisible = true;
  preselectedRows = [];
  selectedData = [];
  viewRowDataView = true;
  editRowDataView = false;

  connectedCallback() {
    //Get account currency and price level
    //Get initial chunk of data with offset set at 0
    console.log("Connected Callback...");
    getAccountRecord({quoteId : this.recordId})
    .then(result => {
      result = JSON.parse(JSON.stringify(result));
      console.log("Account Price Book: " + result[0].Account.Price_Book__c);
      console.log("Account Currency: " + result[0].Account.CurrencyIsoCode);
      this.accountPB = result[0].Account.Price_Book__c;
      this.accountCurrency = result[0].Account.CurrencyIsoCode;
      this.getRecords();
    })
  }

  getRecords() {
    console.log("getRecords...");
    getRecords({
      offSetCount : this.offSetCount,
      accountPB : this.accountPB,
      accountCurrency : this.accountCurrency
    })
    .then(result => {
      // Returned result if from sobject and can't be extended so objectifying the result to make it extensible
      result = JSON.parse(JSON.stringify(result));
      result.forEach(record => {
          record.linkName = '/' + record.Id;
      });
      this.data = [...this.data, ...result];
      this.error = undefined;
      this.loadMoreStatus = '';
      if (this.targetDatatable && this.data.length >= this.totalNumberOfRows) {
          //stop Infinite Loading when threshold is reached
          this.targetDatatable.enableInfiniteLoading = false;
          //Display "No more data to load" when threshold is reached
          this.loadMoreStatus = 'No more data to load';
      }
      //Disable a spinner to signal that data has been loaded
      if (this.targetDatatable) this.targetDatatable.isLoading = false;
    })
    .catch(error => {
      this.error = error;
      this.data = undefined;
      console.log('error : ' + JSON.stringify(this.error));
    });
  }

  handleLoadMore(event) {
    event.preventDefault();
    // increase the offset count by 20 on every loadmore event
    this.offSetCount = this.offSetCount + 20;
    //Display a spinner to signal that data is being loaded
    event.target.isLoading = true;
    //Set the onloadmore event taraget to make it visible to imperative call response to apex.
    this.targetDatatable = event.target;
    //Display "Loading" when more data is being loaded
    this.loadMoreStatus = 'Loading';
    // Get new set of records and append to this.data
    this.getRecords();
    //this.preselectedRows = ['0011I000003jvjIQAQ'];
  }

  selectedRowHandler(event) {
    console.log('Row selected');
    const selectedRows = event.detail.selectedRows;
    let tempPreselectedRows = [];
    console.log('selectedRows: ' + selectedRows);
    for(let i = 0; i < selectedRows.length; i++) {   
      tempPreselectedRows =[...tempPreselectedRows, selectedRows[i].Id];
    }
    console.log('tempPreselectedRows: ' + tempPreselectedRows);
    this.preselectedRows = tempPreselectedRows;
    this.selectedData = event.detail.selectedRows;
  }

  showSelected(event) {
    console.log('Clicked showSelected');
    //this.data = this.selectedData;
    
    if(this.boolVisible) {
      this.boolVisible = false;
      console.log("getSelectedRows => ", this.template.querySelector('lightning-datatable').getSelectedRows());
    } else {
      this.boolVisible = true;
    }
    
  }

  toEditRowData(event) {
    this.editRowDataView = true;
    this.viewRowDataView = false;
  }

  toViewRowData(event) {
    this.editRowDataView = false;
    this.viewRowDataView = true;
  }

}