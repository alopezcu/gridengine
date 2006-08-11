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
package com.sun.grid.ca;

import java.security.KeyStore;
import java.security.cert.X509Certificate;

/**
 * This interface defines all methods which can be exeucted on the 
 * Grid Certificate Authority.
 *
 *
 * @author richard.hierlmeier@sun.com
 */
public interface GridCA {
    
    /**
     *  Initialize the Grid CA
     * 
     * @param countryCode       the two letter country code
     * @param state             the state
     * @param location          the location, e.g city or your buildingcode
     * @param organization      the organization (e.g. your company name)
     * @param organizationUnit  the organizational unit, e.g. your department
     * @param adminMailAddress  the email address of the CA administrator (you!)
     * @throws com.sun.grid.ca.GridCAException 
     */
    public void init(String countryCode,
                     String state,
                     String location,
                     String organization,
                     String organizationUnit,
                     String adminMailAddress) throws GridCAException;
    
    /**
     *  Create private key and certificate for a user.
     *
     *  @param username  name of the user
     *  @param group     group of the user
     *  @param email     email address of the user
     *  @throws GridCAException if the creation of the private key or the certificate fails
     */
    public void createUser(String username, String group, String email) throws GridCAException;
    
    
    /**
     *  Get the X.509 certificate of a user.
     *
     *  @param username  name of the user
     *  @return X.509 certificate
     *  @throws GridCAException if the certificate does not exist
     */
    public X509Certificate getCertificate(String username) throws GridCAException;
    
    /**
     *  Get the X.509 certificate of a daemon.
     *
     *  @param daemon  common name of the daemon
     *  @return X.509 certificate
     *  @throws GridCAException if the certificate does not exist
     */
    public X509Certificate getDaemonCertificate(String daemon) throws GridCAException;
    
    /**
     *  Create a keystore which contains the private key and
     *  certificate of an user.
     *
     *  @param  username         name of the user
     *  @param  keystorePassword password used for encrypt the keystore
     *  @throws GridCAException if the keystore could not be created
     */
    public KeyStore createKeyStore(String username, char [] keystorePassword, char[] privateKeyPassword) throws GridCAException;
    
    
    /**
     *  Renew the certificate of a user.
     *
     *  @param username  name of the user
     *  @param days      validity of the new certificate in days
     *  @return the renewed certificate
     *  @throws CAException if the certificate can not be renewed
     */
    public X509Certificate renewCertificate(String username, int days) throws GridCAException;
    
    
    /**
     *  Renew the certificate of a daemon.
     *
     *  @param daemon  name of the daemon
     *  @param days      validity of the new certificate in days
     *  @return the renewed certificate
     *  @throws CAException if the certificate can not be renewed
     */
    public X509Certificate renewDaemonCertificate(String daemon, int days) throws GridCAException;

    
    /**
     * Create private key and certificate for a grm daemon.
     *
     * @param daemon name of the daemon
     * @param user   username of the daemon (owner of the process)
     * @param email  email address of the process owner
     * @throws com.sun.grid.ca.GridCAException if the create of the daemon failed
     */
    public void createDaemon(String daemon, String user, String email) throws GridCAException;
    
    
    /**
     * Get the keystore for a daemon.
     *
     * This method can be used be the installation to create keystore for
     * the daemon of a grm system.
     *
     * @param daemon name of the daemon
     * @throws com.sun.grid.ca.GridCAException 
     * @return the keystore of the daemon
     */
    public KeyStore createDaemonKeyStore(String daemon) throws GridCAException;
    
}