/*___INFO__MARK_BEGIN__*/
/*************************************************************************
 *
 *  The Contents of this file are made available subject to the terms of
 *  the Sun Industry Standards Source License Version 1.2
 *
 *  Sun Microsystems Inc., March, 2001
 *
 *
 *  Sun Industry Standards Source License Version 1.2
 *  =================================================
 *  The contents of this file are subject to the Sun Industry Standards
 *  Source License Version 1.2 (the "License"); You may not use this file
 *  except in compliance with the License. You may obtain a copy of the
 *  License at http://gridengine.sunsource.net/Gridengine_SISSL_license.html
 *
 *  Software provided under this License is provided on an "AS IS" basis,
 *  WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING,
 *  WITHOUT LIMITATION, WARRANTIES THAT THE SOFTWARE IS FREE OF DEFECTS,
 *  MERCHANTABLE, FIT FOR A PARTICULAR PURPOSE, OR NON-INFRINGING.
 *  See the License for the specific provisions governing your rights and
 *  obligations concerning the Software.
 *
 *   The Initial Developer of the Original Code is: Sun Microsystems, Inc.
 *
 *   Copyright: 2001 by Sun Microsystems, Inc.
 *
 *   All Rights Reserved.
 *
 ************************************************************************/
/*___INFO__MARK_END__*/
/**
 *  Generated from java_simpletest.jsp
 *  !!! DO NOT EDIT THIS FILE !!!
 */
<%
com.sun.grid.cull.JavaHelper jh = (com.sun.grid.cull.JavaHelper)params.get("javaHelper");
com.sun.grid.cull.CullDefinition cullDef = (com.sun.grid.cull.CullDefinition)params.get("cullDef");
com.sun.grid.cull.CullObject cullObj = (com.sun.grid.cull.CullObject)params.get("cullObj");
String classname = jh.getClassName(cullObj);


%>
package com.sun.grid.jgdi.configuration;

import com.sun.grid.jgdi.configuration.reflect.ClassDescriptor;
import junit.framework.*;
import com.sun.grid.jgdi.configuration.*;
import com.sun.grid.jgdi.configuration.reflect.PropertyDescriptor;
import com.sun.grid.jgdi.configuration.reflect.SimplePropertyDescriptor;
import java.io.File;
import java.util.Arrays;
import java.util.Collection;
import java.util.Map;
import java.util.Iterator;
import com.sun.grid.jgdi.configuration.xml.XMLUtil;
import com.sun.grid.jgdi.BaseTestCase;
import com.sun.grid.jgdi.JGDI;
import com.sun.grid.jgdi.JGDIException;
import com.sun.grid.jgdi.TestValueFactory;
import java.util.ArrayList;
import java.util.List;

/**
 *
 */
public class <%=classname%>TestCase extends BaseTestCase {
   
   public  <%=classname%>TestCase(java.lang.String testName) {
      super(testName);
   }
   
   public static Test suite() {
      TestSuite suite = new TestSuite(<%=classname%>TestCase.class);
      return suite;
   }
   
<%
   // --------------------------------------------------------------------------
   // If the add/get/delete operation is available we use the TestValueFactory  
   // to add, get and delete all objects                                        
   // --------------------------------------------------------------------------
   if (cullObj.hasAddOperation() &&                                             
       cullObj.hasGetOperation() &&                                             
       cullObj.hasDeleteOperation()) {                                          
%>  
   
   public void test<%=classname%>AddGetDelete() throws Exception {
   
      Object [] testValues = TestValueFactory.getTestValues(<%=classname%>.class);

      assertTrue("We have no test values for <%=classname%>", testValues.length > 0 );
      
      JGDI jgdi = createJGDI();
      try {
         List differences = new ArrayList();
         
         for (int i = 0; i < testValues.length; i++) {
            <%=classname%> testObj = (<%=classname%>)testValues[i];
            
            jgdi.add<%=classname%>(testObj);
            
            try {

              <%=classname%> retObj = jgdi.get<%=classname%>(<%
              for (int i = 0; i < cullObj.getPrimaryKeyCount(); i++) {
                 com.sun.grid.cull.CullAttr attr = cullObj.getPrimaryKeyAttr(i);          
                 String attrName = jh.getAttrName(attr);                     
                 String gsname =  Character.toUpperCase( attrName.charAt(0) ) +
                                  attrName.substring(1);                     
                 if(i>0) {                                                   
                  %>,<%                                                      
                 }                                                           
                 %>testObj.get<%=gsname%>()<%                              
              }                                                                 
                
              %>);
              
              Util.getDifferences(testObj, retObj, differences);
              
              if (!differences.isEmpty()) {

                 logger.warning("org <%=classname%> is not equal to stored <%=classname%> ------------------------"); 
                 Iterator iter = differences.iterator();
                 while(iter.hasNext()) {
                    
                    Util.Difference diff = (Util.Difference)iter.next();
                    
                    logger.warning(diff.toString());
                 }
                 
              }
              //assertTrue("retobj is not equals to the testobj", differences.isEmpty());
              differences.clear();
              
            } finally {
              jgdi.delete<%=classname%>(testObj);
              
              <%=classname%> retObj = jgdi.get<%=classname%>(<%
                                                                                
              for (int i = 0; i < cullObj.getPrimaryKeyCount(); i++) {                 
                 com.sun.grid.cull.CullAttr attr = cullObj.getPrimaryKeyAttr(i);          
                 String attrName = jh.getAttrName(attr);                     
                 String gsname =  Character.toUpperCase( attrName.charAt(0) ) +
                                  attrName.substring(1);                     

                 if (i>0) {                                                   
                  %>,<%                                                      
                 }                                                           
                  %>testObj.get<%=gsname%>()<%                              
              }                                                                 
                
              %>);
              
              assertNull(testObj + " has not been deleted", retObj);
            }
         
         }
      } finally {
        jgdi.close();
      }
   }
   
<%
   }

   // If the object has the get list operation we can test
   // the serialization of all objects into a xml object
   if (cullObj.hasGetListOperation()) {
%>
   public void test<%=classname%>ListXML() throws Exception {
   
      JGDI jgdi = createJGDI();
      try {
         <%=classname%> obj = null;
         Iterator iter = jgdi.get<%=classname%>List().iterator();
         while (iter.hasNext()) {
            obj = (<%=classname%>)iter.next();

            File file = File.createTempFile("<%=classname%>", ".xml");
            try {
               XMLUtil.write(obj, file);
               <%=classname%> obj1 = (<%=classname%>)XMLUtil.read(file);
               
               // begin debug: check differences
//               List differences = new ArrayList();
//               Util.getDifferences(obj, obj1, differences);
//               if (!differences.isEmpty()) {
//                  logger.warning("org <%=classname%> is not equal to filed/reread obj1 <%=classname%> ------------------------"); 
//                  Iterator it = differences.iterator();
//                  while(it.hasNext()) {
//                     Util.Difference diff = (Util.Difference)it.next();
//                     logger.warning(diff.toString());
//                  }
//               }
//               differences.clear();
               // end debug: check differences
               
               assertTrue("serialized xml object of class <%=classname%> is invalid", 
                          obj.equalsCompletely(obj1) );
            } finally {
              file.delete();
            }
         }
      } finally {
         jgdi.close();
      }
   
   }
<%
   }

   if (cullObj.hasGetOperation() && cullObj.getPrimaryKeyCount() == 0) {
%>
   public void testGetXML() throws Exception {
   
      JGDI jgdi = createJGDI();
      try {
         <%=classname%> obj = jgdi.get<%=classname%>();
         
         File file = File.createTempFile("<%=classname%>", ".xml");
         try {
            XMLUtil.write(obj, file);
            <%=classname%> obj1 = (<%=classname%>)XMLUtil.read(file);
            assertTrue("serialialized xml object of class <%=classname%> is invalid", 
                       obj.equalsCompletely(obj1) );
         } finally {
           file.delete();
         }
      } finally {
         jgdi.close();
      }
   }

<%
   } 
%>
}
