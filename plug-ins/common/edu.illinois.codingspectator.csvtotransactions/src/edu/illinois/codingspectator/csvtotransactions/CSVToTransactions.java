/**
 * This file is licensed under the University of Illinois/NCSA Open Source License. See LICENSE.TXT for details.
 */
package edu.illinois.codingspectator.csvtotransactions;

import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.ParameterException;

/**
 * 
 * @author Mohsen Vakilian
 * 
 */
public class CSVToTransactions {

	private long timeWindowInMinutes;

	private InputStreamReader reader;

	private TransactionWriters transactionWriters;

	private Writer transactionPatternsWriter;

	private String itemColumnName;

	private String timestampColumnName;

	public CSVToTransactions(InputStreamReader reader, OutputStreamWriter transactionWriter, long timeWindowInMinutes, Writer detailedTransactionsWriter, Writer transactionPatternsWriter,
			String itemColumnName, String timestampColumnName) {
		this.reader= reader;
		this.timeWindowInMinutes= timeWindowInMinutes;
		this.transactionWriters= new TransactionWriters(transactionWriter, detailedTransactionsWriter);
		this.transactionPatternsWriter= transactionPatternsWriter;
		this.itemColumnName= itemColumnName;
		this.timestampColumnName= timestampColumnName;
	}

	private List<String> getConstantColumnNames(List<String> allColumnNames) {
		List<String> constantColumnNames= new ArrayList<String>();
		constantColumnNames.addAll(allColumnNames);
		constantColumnNames.remove(itemColumnName);
		constantColumnNames.remove(timestampColumnName);
		return constantColumnNames;
	}

	public void convertCSVToTransactions() throws IOException {
		try {
			TransactionFactory transactionFactory= new TransactionFactory();
			TransactionPatterns transactionPatterns= new TransactionPatterns(itemColumnName);
			CSVReader csvReader= new CSVReader(reader, new String[] { itemColumnName, timestampColumnName });
			List<String> constantColumnNames= getConstantColumnNames(csvReader.getHeader());
			Iterator<Map<String, String>> iterator= csvReader.iterator();
			Transaction lastTransaction= transactionFactory.createTransaction(transactionPatterns);
			UDCRow lastRow= null;
			if (iterator.hasNext()) {
				lastRow= new UDCRow(iterator.next(), itemColumnName, timestampColumnName, constantColumnNames, timeWindowInMinutes);
				lastRow.setTransaction(lastTransaction);
			}
			while (iterator.hasNext()) {
				Map<String, String> currentCSVRow= iterator.next();
				UDCRow currentRow= new UDCRow(currentCSVRow, itemColumnName, timestampColumnName, constantColumnNames, timeWindowInMinutes);
				if (!currentRow.shouldBelongToTheTransactionOf(lastRow)) {
					transactionWriters.writeTransaction(lastTransaction);
					lastTransaction= transactionFactory.createTransaction(transactionPatterns);
				}
				currentRow.setTransaction(lastTransaction);
				lastRow= currentRow;
			}
			transactionWriters.writeTransaction(lastTransaction);
			transactionPatterns.writeTo(transactionPatternsWriter);
		} finally {
			reader.close();
			transactionWriters.close();
			if (transactionPatternsWriter != null) {
				transactionPatternsWriter.close();
			}
		}
	}

	public static void main(String[] args) throws IOException {
		CommandLineParameters params= new CommandLineParameters();
		try {
			JCommander commander= new JCommander(params, args);
			if (params.help) {
				commander.usage();
			} else {
				CSVToTransactions csvToTransactions= new CSVToTransactions(new InputStreamReader(System.in), new OutputStreamWriter(System.out), params.timeWindowInMinutes, new FileWriter(
						params.detailedTransactionsFileName), new FileWriter(params.transactionPatternsFileName), params.itemColumnName, params.timestampColumnName);
				csvToTransactions.convertCSVToTransactions();
			}
		} catch (ParameterException e) {
			new JCommander(params).usage();
		}
	}

}
