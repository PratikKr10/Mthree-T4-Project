/**
 * File: UserProtectWrapper.jsx
 * Purpose: This component provides route protection and authentication state management for protected routes.
 * 
 * Features:
 * - Verifies user authentication status
 * - Manages loading states during authentication checks
 * - Redirects unauthenticated users to the login page
 * - Fetches and updates user profile data
 * - Uses context for user state management
 * - Handles token validation and cleanup
 * 
 * Usage:
 * - Wraps protected routes to ensure authentication
 * - Manages user session state
 * - Provides loading states during authentication checks
 * - Handles unauthorized access attempts
 */

import React, { useContext, useEffect, useState } from 'react'
import { UserDataContext } from '../context/UserContext'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'

const UserProtectWrapper = ({
    children
}) => {
    const token = localStorage.getItem('userToken')
    const navigate = useNavigate()
    const { user, setUser } = useContext(UserDataContext)
    const [ isLoading, setIsLoading ] = useState(true)

    useEffect(() => {
        if (!token) {
            navigate('/login')
        }

        axios.get(`${import.meta.env.VITE_BASE_URL}/users/profile`, {
            headers: {
                Authorization: `Bearer ${token}`
            }
        }).then(response => {
            if (response.status === 200) {
                setUser(response.data)
                // console.log(response.data)
                setIsLoading(false)
            }
        })
            .catch(err => {
                console.log(err)
                localStorage.removeItem('userToken')
                navigate('/login')
            })
    }, [ token ])

    if (isLoading) {
        return (
            <div>Loading...</div>
        )
    }

    return (
        <>
            {children}
        </>
    )
}

export default UserProtectWrapper