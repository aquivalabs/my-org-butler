/**
 * @author         Justus van den Berg (jfwberg@gmail.com)
 * @date           November 2024
 * @copyright      (c) 2024 Justus van den Berg
 * @license        MIT (See LICENSE file in the project root)
 * @description    Class that contains a set of XML Writing  Utilities for the SOAP API
 */
@SuppressWarnings('PMD.CognitiveComplexity, PMD.OneDeclarationPerLine, PMD.ExcessiveParameterList')
public with sharing class XmlWriter {

    /** **************************************************************************************************** **
     **                                          PRIVATE CONSTANTS                                           **
     ** **************************************************************************************************** **/
    // Used XML namespaces (used in both soap requests and responses)
    private static final String SOAP_ENVELOPE_PREFIX  = 'soapenv';
    private static final String SOAP_ENVELOPE_NS      = 'http://schemas.xmlsoap.org/soap/envelope/';
    private static final String SCHEMA_PREFIX         = 'xsd';
    private static final String SCHEMA_NS             = 'http://www.w3.org/2001/XMLSchema';
    private static final String SCHEMA_INSTANCE_PREFIX= 'xsi';
    private static final String SCHEMA_INSTANCE_NS    = 'http://www.w3.org/2001/XMLSchema-instance';

    // XML node names
    private static final String ENVELOPE_NODE         = 'Envelope';
    private static final String HEADER_NODE_NAME      = 'Header';
    private static final String BODY_NODE_NAME        = 'Body';
    
    
    /** **************************************************************************************************** **
     **                                      PRIVATE XML WRITER METHODS                                      **
     ** **************************************************************************************************** **/
    /**
     * @description Method to set the namespace headers
     * @param wsdl  The Wsdl object instance to enhance
     */
    private static void setDefaultNamespaceHeaders(Wsdl wsdl){
        
        // Soap envelope
        wsdl.getNamespaceHeaderMap().put(
            SOAP_ENVELOPE_PREFIX, SOAP_ENVELOPE_NS
        );

        // Schema
        wsdl.getNamespaceHeaderMap().put(
            SCHEMA_PREFIX, SCHEMA_NS
        );

        // Schema instance
        wsdl.getNamespaceHeaderMap().put(
            SCHEMA_INSTANCE_PREFIX, SCHEMA_INSTANCE_NS
        );
    }


    /**
     * @description Method to set the namespace headers that are specific to the Api Service
     * @param wsdl  The Wsdl object instance to enhance
     */
    private static void setServiceNamespaceHeader(Wsdl wsdl){
        // API specific namespace
        wsdl.getNamespaceHeaderMap().put(
            wsdl.getServiceNamespacePrefix(),
            wsdl.getServiceNamespace()
        );
    }


    /**
     * @description Method to write the namespace headers
     * @param w     The XmlStreamWriter instance to use
     * @param wsdl  The Wsdl object instance to enhance
     */
    private static void writeNamespaceHeader(XmlStreamWriter w, Wsdl wsdl){
        
        // Set the required namespaces
        setDefaultNamespaceHeaders(wsdl);
        setServiceNamespaceHeader(wsdl);

        // Iterate the namespace map and populate the namespaces
        for(String namespaceName : wsdl.getNamespaceHeaderMap().keySet()){
            w.writeNamespace(
                namespaceName,
                wsdl.getNamespaceHeaderMap().get(namespaceName)
            );
        }
    }


    /**
     * @description Method to write the XML header
     * @param w     The XmlStreamWriter instance to use
     */
    private static void writeXmlHeader(XmlStreamWriter w){
        w.writeStartDocument('UTF-8', '1.0'); 
    }


    /**
     * @description Start <Envelope>
     * @param w     The XmlStreamWriter instance to use
     */
    private static void writeSoapEnvelopeOpenTag(XmlStreamWriter w){
        w.writeStartElement(
            SOAP_ENVELOPE_PREFIX,
            ENVELOPE_NODE,
            SOAP_ENVELOPE_NS
        );
    }

    // End <Envelope>
        /**
     * @description Start <Envelope>
     * @param w     The XmlStreamWriter instance to use
     */
    private static void writeSoapEnvelopeCloseTag(XmlStreamWriter w){    
        w.writeEndElement(); 
    }


    // Start <Body>
    /**
     * @description Start <Body>
     * @param w     The XmlStreamWriter instance to use
     */
    private static void writeSoapBodyOpenTag(XmlStreamWriter w){    
        w.writeStartElement(
            SOAP_ENVELOPE_PREFIX,
            'Body',
            ''
        );
    }


    /**
     * @description Start <Body>
     * @param w     The XmlStreamWriter instance to use
     */
    private static void writeSoapBodyCloseTag(XmlStreamWriter w){    
        w.writeEndElement(); 
    }

    // Start <SoapAction>
        /**
     * @description Start <SoapAction>
     * @param w     The XmlStreamWriter instance to use
     */
    private static void writeSoapActionOpenTag(XmlStreamWriter w, Wsdl wsdl){
        w.writeStartElement(
            wsdl.getServiceNamespacePrefix(),
            wsdl.getSoapAction(),
            ''
        );
    }

    /**
     * @description End <SoapAction>
     * @param w     The XmlStreamWriter instance to use
     */
    private static void writeSoapActionCloseTag(XmlStreamWriter w){    
        w.writeEndElement(); 
    }


    /**
     * @description Start <Header>
     * @param w     The XmlStreamWriter instance to use
     */
    private static void writeHeaderOpenTag(XmlStreamWriter w){
        w.writeStartElement(
            SOAP_ENVELOPE_PREFIX,
            HEADER_NODE_NAME,
            ''
        );
    }
    
    /**
     * @description End <Header>
     * @param w     The XmlStreamWriter instance to use
     */
    private static void writeHeaderCloseTag(XmlStreamWriter w){    
        w.writeEndElement(); 
    }


    /** **************************************************************************************************** **
     **                                      PUBLIC XML WRITER METHODS                                       **
     ** **************************************************************************************************** **/
    /**
     * @description Method to write the FULL soap request body
     */
    public static void writeFullSoapRequestBody(Wsdl wsdl){
        
        // Setup new XmlWriter()
        XmlStreamWriter w = new XmlStreamWriter();

        // Write all
        writeXmlHeader(w);
        writeSoapEnvelopeOpenTag(w);
        writeNamespaceHeader(w,wsdl);
        writeHeaderOpenTag(w);
        wsdl.writeSoapHeaderContent(w);
        writeHeaderCloseTag(w);
        writeSoapBodyOpenTag(w);
        writeSoapActionOpenTag(w,wsdl);
        wsdl.writeSoapBodyContent(w);
        writeSoapActionCloseTag(w);
        writeSoapBodyCloseTag(w);
        writeSoapEnvelopeCloseTag(w);

        // Get the full request body as a string and set the request body variable
        wsdl.setSoapRequestBody(w.getXmlString()); 

        // Close the XML writer
        w.close();
    }


    /** **************************************************************************************************** **
     **                                      PUBLIC XML WRITER METHODS                                       **
     ** **************************************************************************************************** **/
    public static void write(String namespacePrefix, XmlStreamWriter w, Object input){
        if(input instanceOf Map<String,Object>){
            writeXsw(namespacePrefix, w, (Map<String,Object>) input);
        }else if(input instanceOf Object[]){
            writeXsw(namespacePrefix, w, (Object[]) input);
        }
    }

    
    /** **************************************************************************************************** **
     **                                      PRIVATE XML WRITER METHODS                                      **
     ** **************************************************************************************************** **/
    /**
     * Method to write a list of objectMap items recursively to an existing stream writer
     * this is used to add pieces of XML to an existing XML payload.
     * For example you can add data to a SOAP header and then add data to a SOAP Body
     *
     * Note:     This method is not intended for complex XML writing, it handles a single namespace
     *             only and does not support the writing of element attributes
     * @param namespacePrefix The namespace to be written
     * @param w               The XmlStreamWriter object to add the data to
     * @param objectMapList   The data that should be added to the XML Stream
     */
    private static void writeXsw(String namespacePrefix, XmlStreamWriter w, Object[] objectList){
        for(Integer i=0,max=objectList.size();i<max;i++){
            if(objectList[i] instanceOf Map<String,Object>){
                writeXsw(namespacePrefix, w, (Map<String,Object>) objectList[i]);
            }
        }
    }


    /**
     * Method to write objectMap items recursively to an existing stream writer
     * thsis is used to add pieces of XML to an existing XML payload.
     * For example you can add data to a SOAP header and then add data to a SOAP Body
     *
     * Note:     This method is not intended for complex XML writing, it handles a single namespace
     *             only and does not support the writing of element attributes
     * @param namespacePrefix The namespace to be written
     * @param w               The XmlStreamWriter object to add the data to
     * @param objectMap       The data that should be added to the XML Stream
     */
    private static void writeXsw(String namespacePrefix, XmlStreamWriter w, Map<String,Object> objectMap){

        // Start element namespaces should be empty
        String namespaceUri = (namespacePrefix == null ? null : '');

        for(String mapKey : objectMap.keySet()){

            // Handle objectMap map, child mapKey/value pair objects
            if(objectMap.get(mapKey) instanceOf Map<String,Object>){
                w.writeStartElement(namespacePrefix, mapKey,  namespaceUri);
                writeXsw(namespacePrefix, w, (Map<String,Object>) objectMap.get(mapKey));
                w.writeEndElement();

            // Handle objectMap list (repeated XML element)
            }else if(objectMap.get(mapKey) instanceOf List<Object>){
                writeXsw(namespacePrefix, w, mapKey, (Object[]) objectMap.get(mapKey));

            // Actual value, not a map or a list, write the value
            }else{
                w.writeStartElement(namespacePrefix, mapKey, namespaceUri);
                w.writeCharacters((objectMap.get(mapKey) != null) ? String.valueOf(objectMap.get(mapKey)) : '' );
                w.writeEndElement();
            }
        }
    }


    /**
     * Method to write write objectMap items recursively
     * @param namespacePrefix The namespace to be written
     * @param w               The XmlStreamWriter object to add the data to
     * @param mapKey          The parent map key to get the child elements
     * @param objectList      The data that should be added to the XML Stream
     */
    private static void writeXsw(String namespacePrefix, XmlStreamWriter w, String mapKey, Object[] objectList){

        // Start element namespaces should be empty
        String namespaceUri = (namespacePrefix == null ? null : '');

        // Iterate all the objects in the list
        for(Integer i=0,max=objectList.size();i<max;i++){
            w.writeStartElement(namespacePrefix, mapKey, namespaceUri );

            // Handle objectMap map
            if(objectList[i] instanceOf Map<String,Object>){
                writeXsw(namespacePrefix, w,(Map<String,Object>) objectList[i]);

            // Actual value, not a map or a list, write the value
            }else{
                w.writeCharacters( (objectList[i] != null) ? String.valueOf(objectList[i]) : '' );
            }
            w.writeEndElement();
        }
    }
}